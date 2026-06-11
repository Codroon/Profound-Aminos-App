import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

async function sendToAdmins(payload: { title: string, body: string, data: any, prefKey?: string }) {
    const db = admin.firestore();
    try {
        const RETENTION_DAYS = 365; 
        const expireAt = admin.firestore.Timestamp.fromMillis(
            Date.now() + RETENTION_DAYS * 24 * 60 * 60 * 1000
        );
        await db.collection("notifications").add({
            title: payload.title,
            body: payload.body,
            type: (payload.data && payload.data.type) || "",
            prefKey: payload.prefKey || "",
            data: payload.data || {},
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            expireAt: expireAt,
        });
    } catch (err) {
        console.error("Failed to persist notification history:", err);
        // Don't block the push if history write fails.
    }

    const devicesRef = db.collection("admin_devices");
    const snapshot = await devicesRef.get();

    const notifications = snapshot.docs.map(async doc => {
        const token = doc.data().token;
        const preferences = doc.data().preferences || {};

        if (payload.prefKey && preferences[payload.prefKey] === false) {
            console.log(`Push disabled by user preference '${payload.prefKey}' for token: ${token}`);
            return;
        }

        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: payload.title,
                        body: payload.body,
                    },
                    data: {
                        ...payload.data,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    android: {
                        priority: "high",
                        notification: {
                            channelId: payload.data.channelId || "orders_channel",
                        }
                    }
                });
            } catch (err: any) {
                console.error(`Error sending push to token: ${token}`, err);
                // Clean up/delete the token if it is no longer registered/valid
                if (
                    err.code === "messaging/registration-token-not-registered" ||
                    err.code === "messaging/invalid-argument" ||
                    (err.message && err.message.includes("registration token is not registered"))
                ) {
                    await doc.ref.delete();
                    console.log(`Deleted stale/unregistered token from DB: ${token}`);
                }
            }
        }
    });

    await Promise.all(notifications);
}

export const wcWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const event = req.headers["x-wc-webhook-topic"]?.toString() || "order.updated";
        const body = req.body;
        const orderId = body.id || "N/A";
        const firstName = body.billing?.first_name || "";
        const lastName = body.billing?.last_name || "";
        const customerName = `${firstName} ${lastName}`.trim() || "Customer";
        const total = body.total || "0.00";
        const currency = body.currency || "USD";
        const status = body.status || "updated";
        let title = "Order Update";
        let message = `Order #${orderId} updated.`;
        let channelId = "orders_channel";
        let hasTracking = false;
        let trackingNumber = "";
        let trackingProvider = "";
        if (body.meta_data && Array.isArray(body.meta_data)) {
            for (const meta of body.meta_data) {
                if (meta.key === "_wc_shipment_tracking_items") {
                    const trackingItems = meta.value;
                    if (Array.isArray(trackingItems) && trackingItems.length > 0) {
                        hasTracking = true;
                        trackingNumber = trackingItems[0].tracking_number || "";
                        trackingProvider = trackingItems[0].tracking_provider || "";
                    }
                }
            }
        }

        let prefKey = "orders_update";

        if (event === "order.created") {
            title = "New Order!";
            message = `New order #${orderId} by ${customerName} — ${total} ${currency}.`;
            channelId = "orders_channel";
            prefKey = "orders_create";
        } else if (event === "order.refunded" || status === "refunded") {
            title = "Order Refunded";
            message = `Order #${orderId} refunded.`;
            channelId = "orders_channel";
            prefKey = "orders_refund";
        } else if (event === "order.updated") {
            if (status === "completed") {
                // If order status is completed, the shipment is Delivered!
                title = "Shipment Delivered";
                message = `Order #${orderId} delivered to the customer.`;
                channelId = "shipping_channel";
                prefKey = "shipment_delivered";
            } else if (status === "cancelled") {
                title = "Order Cancelled";
                message = `Order #${orderId} cancelled.`;
                channelId = "orders_channel";
                prefKey = "orders_refund";
            } else if (hasTracking) {
                // If the order is updated and tracking is attached, we treat it as Shipment Created / Transit
                title = "Shipment Created";
                message = `Shipment created for Order #${orderId}.`;
                channelId = "shipping_channel";
                prefKey = "shipment_create";
            } else {
                title = "Order Updated";
                message = `Order #${orderId} status updated to ${status}.`;
                channelId = "orders_channel";
                prefKey = "orders_update";
            }
        }

        await sendToAdmins({
            title: title,
            body: message,
            prefKey: prefKey,
            data: {
                type: channelId === "shipping_channel" ? "shipment" : event,
                order_id: orderId.toString(),
                status: status,
                tracking_number: trackingNumber,
                carrier: trackingProvider,
                channelId: channelId
            }
        });

        res.status(200).send("OK");
    } catch (error) {
        console.error("WooCommerce Webhook error:", error);
        res.status(500).send("Internal Server Error");
    }
});

// 2. Gorgias Webhook
export const gorgiasWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const body = req.body;
        const event = (body.event_type || "").toString();

        // Extract variables with absolute safety
        const ticketId = body.object?.id || body.object?.ticket_id || "N/A";
        const customerName = body.object?.customer?.name || body.object?.requester?.name || "Customer";
        const status = body.object?.status || body.object?.state || "updated";

        // Sender name for messages
        const senderName = body.object?.from_agent ? "Agent" : (body.object?.sender?.name || customerName);

        let title = "Support Ticket";
        let message = `Ticket #${ticketId} updated.`;
        let prefKey = "gorgias_update";

        // Gorgias Events mapping
        if (event === "ticket_created" || event === "ticket.created") {
            title = "New Support Ticket";
            message = `New ticket #${ticketId} from ${customerName}.`;
            prefKey = "gorgias_create";
        } else if (event === "ticket_updated" || event === "ticket.updated") {
            title = "Ticket Updated";
            message = `Ticket #${ticketId} updated to ${status}.`;
            prefKey = "gorgias_update";
        } else if (event === "message_created" || event === "message.created") {
            title = "New Support Message";
            message = `New message on Ticket #${ticketId} from ${senderName}.`;
            prefKey = "gorgias_message";
        }

        await sendToAdmins({
            title: title,
            body: message,
            prefKey: prefKey,
            data: {
                type: "ticket",
                ticket_id: ticketId.toString(),
                status: status,
                channelId: "support_channel"
            }
        });

        res.status(200).send("OK");
    } catch (error) {
        console.error("Gorgias Webhook error:", error);
        res.status(500).send("Internal Server Error");
    }
});

// 3. Shipping API Webhook (Standalone fallback)
export const shippingWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const body = req.body;
        const event = (body.event || "tracking.updated").toString();
        const orderId = body.order_id || "N/A";
        const trackingStatus = body.tracking_status || "in transit";

        let title = "Shipping Update";
        let message = `Shipping update for Order #${orderId}.`;
        let prefKey = "shipment_update";

        if (event === "shipment.created") {
            title = "Shipment Created";
            message = `Shipment created for Order #${orderId}.`;
            prefKey = "shipment_create";
        } else if (event === "tracking.updated") {
            title = "Shipment Update";
            message = `Order #${orderId} is now ${trackingStatus}.`;
            prefKey = "shipment_update";
        } else if (event === "tracking.delivered") {
            title = "Shipment Delivered";
            message = `Order #${orderId} delivered to the customer.`;
            prefKey = "shipment_delivered";
        }

        await sendToAdmins({
            title: title,
            body: message,
            prefKey: prefKey,
            data: {
                type: "shipping",
                order_id: orderId.toString(),
                tracking_status: trackingStatus,
                channelId: "shipping_channel"
            }
        });

        res.status(200).send("OK");
    } catch (error) {
        console.error("Shipping Webhook error:", error);
        res.status(500).send("Internal Server Error");
    }
});
