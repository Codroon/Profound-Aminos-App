# Profound Aminos – Store Management App

A Flutter app for managing the Profound Aminos WooCommerce store, with WordPress, Gorgias (support) and ReachShip (shipping) integrations.

This document summarizes the work done in this round of changes.

## Overview of what we improved

We started by reworking the UI across the whole app to give it a cleaner, more consistent look, and then built out the feature set screen by screen.

### 1. Dashboard

The dashboard is the home of the app and now surfaces the most important numbers at a glance:

- **Total products, total orders and revenue**, each with its own chart, period filters (today / this week / this month / this year / all time) and the supporting detail behind every figure.
- A **shipping overview** giving a quick read on the current shipping situation.
- The **3 most recent orders**, so the latest activity is visible without leaving the dashboard.

### 2. Shipping

The second tab is a dedicated shipping screen. It lists the full shipping details for every shipment, with pagination so the complete history can be browsed without loading everything at once.

### 3. Support (Gorgias)

The Gorgias tab already existed, so here we focused on improving the UI to match the rest of the app.

### 4. Notifications

We added a fourth tab for notifications and implemented the full notification flow. Notifications cover **orders, Gorgias tickets and shipping**. Each event is stored in Firebase and the app fetches the history back from there, so notifications are kept across devices rather than only living on one phone.

### 5. Settings

The settings screen got a UI refresh and two additions:

- A new **notification preferences** screen where you can choose exactly which kinds of notifications you want to receive.
- **Light and dark mode** for the entire app, toggled from a button on the settings page.

## Getting started

```bash
flutter pub get      # install dependencies
flutter run          # run on a connected device or emulator
```

Store credentials (WooCommerce, WordPress, Gorgias, ReachShip) are entered at runtime from the settings screen and stored securely on the device — nothing is hardcoded.
