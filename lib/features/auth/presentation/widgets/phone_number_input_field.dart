import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PhoneNumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const PhoneNumberInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            dialogBackgroundColor: AppColors.backgroundDark,
            onChanged: (countryCode) {
              // handle selected country
            },
            flagDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            initialSelection: 'BR',
            favorite: ['+55', 'BR'],
            showCountryOnly: true,
            showOnlyCountryWhenClosed: true,
            alignLeft: false,
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            flagWidth: 20,
          ),
          SizedBox(
            width: 10,
            height: 20,
            child: VerticalDivider(
              color: AppColors.border,
              thickness: 1,
              width: 12,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              onChanged: onChanged,
              validator: validator,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Please enter phone number',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
              ),
              cursorColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
