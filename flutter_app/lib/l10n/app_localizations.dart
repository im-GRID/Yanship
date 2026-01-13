// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      // Existing keys
      'app_title': 'YanShip Delivery',
      'driver_home': 'Driver Home',
      'orders': 'Orders',
      'new_order': 'New Order',
      'order_details': 'Order Details',
      'order_status': 'Order Status',
      'order_id': 'Order ID',
      'customer_name': 'Customer Name',
      'delivery_address': 'Delivery Address',
      'phone_number': 'Phone Number',
      'order_total': 'Order Total',
      'accept_order': 'Accept Order',
      'decline_order': 'Decline Order',
      'mark_delivered': 'Mark as Delivered',
      'mark_picked_up': 'Mark as Picked Up',
      'pending': 'Pending',
      'accepted': 'Accepted',
      'picked_up': 'Picked Up',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_mode': 'System Mode',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'notification_title': 'Order Status Update',
      'order_accepted': 'Order has been accepted',
      'order_picked_up': 'Order has been picked up',
      'order_delivered': 'Order has been delivered',
      'order_cancelled': 'Order has been cancelled',
      'confirm_delivery': 'Confirm Delivery',
      
      // Authentication & Welcome page keys
      'welcome': 'Welcome',
      'skip': 'Skip',
      'login': 'Login',
      'sign_in': 'Sign In',
      'register': 'Register',
      'sign_up': 'Sign Up',
      'create_account': 'Create Account',
      'email_label': 'Email',
      'password_label': 'Password',
      'confirm_password_label': 'Confirm Password',
      'first_name_label': 'First Name',
      'last_name_label': 'Last Name',
      'username_label': 'Username',
      'phone_label': 'Phone',
      'address_label': 'Address',
      'city_label': 'City',
      'company_label': 'Company',
      'already_have_account': 'Already have an account?',
      'dont_have_account': 'Don\'t have an account?',
      'please_enter_email_auth': 'Please enter your email',
      'please_enter_password_auth': 'Please enter your password',
      'please_enter_first_name_auth': 'Please enter first name',
      'please_enter_last_name_auth': 'Please enter last name',
      'please_enter_username_auth': 'Please enter username',
      'please_enter_phone_auth': 'Please enter phone number',
      'please_enter_address_auth': 'Please enter address',
      'please_enter_city_auth': 'Please enter city',
      'password_min_length_auth': 'Password must be at least 6 characters long',
      'passwords_not_match_auth': 'Passwords do not match',
      'login_success': 'Login successful',
      'register_success': 'Registration successful',
      'login_failed': 'Login failed',
      'register_failed': 'Registration failed',
      'are_you_sure_delivery': 'Are you sure you want to mark this order as delivered?',
      'yes': 'Yes',
      'no': 'No',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'no_orders': 'No orders available',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'changeStatus': 'Change Status',
      'uploadProof': 'Upload Proof',
      'generateInvoice': 'Generate Invoice',
      
      // Dashboard keys
      'dashboard': 'Dashboard',
      'driver_dashboard': 'Driver Dashboard',
      'driver_id': 'Driver ID',
      'total_orders': 'Total Orders',
      'returned': 'Returned',
      'performance_overview': 'Performance Overview',
      'success_rate': 'Success Rate',
      'earnings': 'Earnings',
      'delivered_orders': 'Delivered Orders',
      'delivered_amount': 'Driver Earnings (MAD)',
      'average_ticket': 'Average Ticket',
      'pending_invoices': 'Pending Invoices',
      
      // Order Details keys
      'order_information': 'Order Information',
      'order_no': 'Order No',
      'order_encoded': 'Order Encoded',
      'order_date': 'Order Date',
      'customer_information': 'Customer Information',
      'receiver_name': 'Receiver Name',
      'person_receives': 'Person Receives',
      'phone': 'Phone',
      'address': 'Address',
      'city': 'City',
      'payment_information': 'Payment Information',
      'price': 'Price',
      'price_after_fee': 'Price After Fee',
      'to': 'To',
      'order_timeline': 'Order Timeline',
      'no_timeline_events': 'No timeline events',
      'notes': 'Notes',
      'print_label': 'Print Label',
      'generate_shipping_label': 'Generate shipping label',
      
      // Order card and action keys
      'confirm_order_dialog_title': 'Confirm Order',
      'confirm_order_dialog_message': 'This will change the status to "Confirmed" and the order will be ready for pickup.',
      'failed_to_confirm_order': 'Failed to confirm order',
      'editable': 'Editable',
      'na': 'N/A',
      'modify_order_details': 'Modify order details',
      'show_delivery_information': 'Show delivery information',
      'mark_confirmed_ready': 'Mark as confirmed and ready',
    'delete_order_permanently': 'Delete order permanently',
    'orders_picked_up_successfully': 'orders picked up successfully',
    'failed_to_pickup_orders': 'Failed to pickup orders',
    'order_confirmed_successfully': 'has been confirmed successfully',
    'failed_to_cancel_order': 'Failed to cancel order',
    'order': 'Order',
    'error_picking_up_orders': 'Error picking up orders',
    'error_order_id_not_found': 'Error: Order ID not found',
    'error_cancelling_order': 'Error cancelling order',
    'error_tracking_number_not_found': 'Error: Tracking number not found',
    'error_confirming_order': 'Error confirming order',
    'error_loading_orders': 'Error loading orders',
    'recipient_name': 'Recipient',
    'no_phone_number': 'No phone number',
    'no_address': 'No address',
    'status_history': 'Status History',
      'delivery_status': 'Delivery Status',
      'completed': 'Completed',
      'proof_uploaded': 'Proof Uploaded',
      'proof_file': 'Proof File',
      'invoice_status': 'Invoice Status',
      'generated': 'Generated',
      'not_generated': 'Not Generated',
      'status_note': 'Status Note',
      'status_cannot_change': 'This status cannot be changed',
      'locked': 'Locked',
      
      // HomePage specific keys
      'all': 'All',
      'unknown': 'Unknown',
      'print_bon_reception': 'Print Bon de Réception',
      'unknown_city': 'Unknown City',
      'status_created': 'Created',
      'status_confirmed': 'Confirmed',
      'status_in_transit': 'In Transit',
      'status_picked_up': 'Picked up',
      'status_out_for_delivery': 'Out for Delivery',
      'status_attempted_delivery': 'Attempted Delivery',
      'status_delivered': 'Delivered',
      'status_returned': 'Returned',
      'status_cancelled': 'Cancelled',
      'status_rejected': 'Rejected',
      
      // Profile keys
      'profile': 'Profile',
      'personal_information': 'Personal Information',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'email': 'Email',
      'username': 'Username',
      'rib': 'RIB',
      'cne': 'CNE',
      'ice': 'ICE',
      'last_login': 'Last Login',
      'registration_date': 'Registration Date',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'save_changes': 'Save Changes',
      'profile_updated_success': 'Profile updated successfully',
      'please_enter_first_name': 'Please enter first name',
      'please_enter_last_name': 'Please enter last name',
      'please_enter_email': 'Please enter email',
      'please_enter_valid_email': 'Please enter a valid email',
      'please_enter_username': 'Please enter username',
      'please_enter_rib': 'Please enter RIB',
      'please_enter_cne': 'Please enter CNE',
      'please_enter_ice': 'Please enter ICE',
      'please_enter_phone': 'Please enter phone number',
      'please_enter_address': 'Please enter address',
      'please_enter_city': 'Please enter city',
      'password_min_length': 'Password must be at least 6 characters long',
      'passwords_not_match': 'Passwords do not match',
      'rating': 'Rating',
      'connection_error': 'Connection error to server',

      // Help & Support keys
      'help_support': 'Help & Support',
      'emergency_support': 'Emergency Support',
      'emergency_support_desc': 'For urgent delivery issues or emergencies',
      'call_now': 'Call Now',
      'whatsapp': 'WhatsApp',
      'could_not_open_whatsapp': 'Could not open WhatsApp',
      'quick_actions': 'Quick Actions',
      'driver_status': 'Driver Status',
      'driver_status_desc': 'Update availability, location settings',
      'delivery_history': 'Delivery History',
      'delivery_history_desc': 'View past deliveries and earnings',
      'payment_info': 'Payment Info',
      'payment_info_desc': 'Check earnings and payment methods',
      'opening_driver_status': 'Opening driver status...',
      'opening_delivery_history': 'Opening delivery history...',
      'opening_payment_info': 'Opening payment info...',
      'submit_support_request': 'Submit Support Request',
      'issue_type': 'Issue Type',
      'technical_issue': 'Technical Issue',
      'technical_issue_desc': 'App crashes, login problems, GPS issues',
      'delivery_problem': 'Delivery Problem',
      'delivery_problem_desc': 'Cannot find address, customer unavailable',
      'payment_issue': 'Payment Issue',
      'payment_issue_desc': 'Missing payments, incorrect amounts',
      'account_problem': 'Account Problem',
      'account_problem_desc': 'Profile updates, verification issues',
      'other': 'Other',
      'other_desc': 'General questions or other concerns',
      'describe_issue': 'Describe the Issue',
      'describe_issue_placeholder': 'Please describe your issue in detail...',
      'please_describe_issue': 'Please describe your issue',
      'provide_more_details': 'Please provide more details (at least 10 characters)',
      'submit_request': 'Submit Request',
      'support_request_success': 'Support request submitted successfully! We\'ll get back to you soon.',
      'frequently_asked_questions': 'Frequently Asked Questions',
      'faq_gps_title': 'GPS is not working properly',
      'faq_gps_answer': 'Try enabling location services in your device settings, restart the app, or check if you have the latest app version installed.',
      'faq_payment_title': 'When will I receive my payment?',
      'faq_payment_answer': 'Payments are processed weekly on Fridays. You should receive your earnings within 2-3 business days after processing.',
      'faq_customer_title': 'Customer is not available',
      'faq_customer_answer': 'Try calling the customer first. If no response, wait 5 minutes and try again. After 15 minutes, you can mark as "attempted delivery" and return the package.',

      // Invoice keys - ADDED
      'invoices': 'Invoices',
      'invoice_no': 'Invoice No.',
      'date': 'Date',
      'amount': 'Amount',
      'status': 'Status',
      'download': 'Download',
      'view': 'View',
      'coming_soon': 'Coming Soon!',
      'no_invoices_found': 'No invoices found',
      'paid': 'Paid',
      'history': 'History',
      
      // Welcome page specific keys
      'app_name': 'Yanship',
      'light_mode_tooltip': 'Light mode',
      'dark_mode_tooltip': 'Dark mode',
      'we_are_yanship': 'We are Yan Ship',
      'yanship_description': 'We are here as a partner we need you to earn more because your gain is our too, we offer delivery service also we suggest you a complete pack from suppliers to delivery without spend time on that to keep focus on scaling. That\'s why you can name us as your business extension.',
      'features': 'Features',
      'feature_description': 'Discover our comprehensive delivery solutions',
      'fast_delivery': 'Fast Delivery',
      'secure_payment': 'Secure Payment',
      'real_time_tracking': 'Real Time Tracking',
      'all_in_one_pack': 'We offer all in one pack',
      'all_in_one_pack_desc': 'No need to distracting between a lot of services we give you a complete pack. Just scale it.!',
      'fast_shipping': 'Fast shipping',
      'fast_shipping_desc': 'Our delivery time to all Morocco with an average time of 24H. Yalla.!',
      'payment_24h': '24H payment',
      'payment_24h_desc': 'We send payments daily so there is no late cash flow. Money ringtone.!',
      'pricing': 'Pricing',
      'choose_plan': 'Choose Your Plan',
      'silver': 'Silver',
      'gold': 'Gold',
      'platinum': 'Platinum',
      'month': '/month',
      'basic_features': 'Basic delivery features',
      'advanced_features': 'Advanced features + priority support',
      'premium_features': 'All features + premium support',
      'contact_us': 'Contact Us',
      'get_in_touch': 'Get in Touch',
      'contact_description': 'Have questions? We\'d love to hear from you.',
      'name': 'Name',
      'name_hint': 'Enter your name',
      'email_hint': 'Enter your email',
      'phone_hint': 'Enter your phone number',
      'message': 'Message',
      'message_hint': 'Enter your message',
      'send_message': 'Send Message',
      'name_required': 'Name is required',
      'email_required': 'Email is required',
      'email_invalid': 'Please enter a valid email',
      'phone_required': 'Phone number is required',
      'message_required': 'Message is required',
      'message_sent': 'Message sent successfully!',
      'message_error': 'Failed to send message. Please try again.',
      
      // VIP Plans and Pricing
      'vip_plans': 'VIP Plans',
      'choose_your_plan': 'Choose Your Plan',
      'most_popular': 'Most Popular',
      'per_month': 'per month',
      'get_started': 'Get Started',
      'select_plan': 'Select Plan',
      'free_trial': 'Free Trial',
      'unlimited_deliveries': 'Unlimited Deliveries',
      'priority_support_plan': 'Priority Support',
      'advanced_analytics': 'Advanced Analytics',
      'custom_branding': 'Custom Branding',
      'api_access': 'API Access',
      
      // Home Page Elements
      'welcome_back': 'Welcome Back',
      'main_dashboard': 'Dashboard',
      'quick_stats': 'Quick Stats',
      'total_deliveries': 'Total Deliveries',
      'completed_orders': 'Completed Orders',
      'pending_orders': 'Pending Orders',
      'earnings_today': 'Today\'s Earnings',
      'recent_orders': 'Recent Orders',
      'view_all_orders': 'View All Orders',
      'no_recent_orders': 'No recent orders',
      'quick_actions_home': 'Quick Actions',
      'new_delivery': 'New Delivery',
      'track_package': 'Track Package',
      'customer_support': 'Customer Support',
      'performance': 'Performance',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'delivery_rate': 'Delivery Rate',
      'customer_rating': 'Customer Rating',
      'on_time_delivery': 'On-time Delivery',
      
      // Create Order Page
      'create_new_order': 'Create New Order',
      'customer_info': 'Customer Information',
      'customer_name_field': 'Customer Name',
      'customer_phone': 'Customer Phone',
      'customer_email': 'Customer Email',
      'delivery_info': 'Delivery Information',
      'pickup_address': 'Pickup Address',
      'delivery_address_field': 'Delivery Address',
      'delivery_notes': 'Delivery Notes',
      'package_details': 'Package Details',
      'package_description': 'Package Description',
      'package_weight': 'Package Weight',
      'package_dimensions': 'Package Dimensions',
      'fragile_item': 'Fragile Item',
      'express_delivery': 'Express Delivery',
      'delivery_fee': 'Delivery Fee',
      'total_amount': 'Total Amount',
      'payment_method': 'Payment Method',
      'cash_on_delivery': 'Cash on Delivery',
      'prepaid': 'Prepaid',
      'create_order_btn': 'Create Order',
      'order_created_successfully': 'Order created successfully',
      'please_fill_required_fields': 'Please fill all required fields',
      
      // Create Order Page Additional Fields
      'create_order_page_title': 'Create New Order',
      'create_order_description': 'Fill in all the details below to create your delivery order',
      'recipient_name_field': 'Recipient Name',
      'recipient_name_hint': 'Enter full name',
      'phone_number_field': 'Phone Number',
      'phone_number_hint': '+1 (555) 123-4567',
      'city_field': 'City',
      'city_hint': 'Enter city',
      'delivery_address_field_label': 'Delivery Address',
      'delivery_address_hint': 'Enter complete delivery address',
      'order_price_field': 'Order Price',
      'order_price_hint': '\$0.00',
      'authorize_open_package': 'Authorize to Open Package',
      'authorize_open_package_description': 'Check this box if you authorize the delivery person to open the package for verification purposes',
      
      // Form Validation Messages
      'name_required_error': 'Name is required',
      'phone_required_error': 'Phone number is required',
      'city_required_error': 'City is required',
      'delivery_address_required_error': 'Delivery address is required',
      'price_required_error': 'Price is required',
      'valid_price_required_error': 'Enter a valid price',
      
      // Error Messages
      'order_creation_failed': 'Order Creation Failed',
      'try_again_button': 'Try Again',
      
      // Success Dialog Messages
      'order_success_description': 'Your delivery order has been created and will be processed shortly. You\'ll receive updates via notifications.',
      'create_another_order': 'Create Another',
      'back_to_home': 'Back to Home',
      
      // Edit Order Page
      'edit_order': 'Edit Order',
      'update_order': 'Update Order',
      'order_updated_successfully': 'Order updated successfully',
      'cancel_order': 'Cancel Order',
      'order_cancelled_successfully': 'Order cancelled successfully',
      'are_you_sure_cancel': 'Are you sure you want to cancel this order?',
      'order_info': 'Order Information',
      'tracking_number': 'Tracking Number',
      'order_date_field': 'Order Date',
      'estimated_delivery': 'Estimated Delivery',
      'actual_delivery': 'Actual Delivery',
      'delivery_proof': 'Delivery Proof',
      'upload_proof': 'Upload Proof',
      'add_note': 'Add Note',
      'order_notes': 'Order Notes',
      
      // Edit Order Page Additional Fields
      'edit_order_title': 'Edit Order',
      'edit_order_subtitle': 'Make changes to order details',
      'customer_info_edit_section': 'Customer Information',
      'customer_info_edit_subtitle': 'Update recipient details',
      'delivery_info_edit_section': 'Delivery Information',
      'delivery_info_edit_subtitle': 'Update delivery address',
      'order_details_edit_section': 'Order Details',
      'order_details_edit_subtitle': 'Update pricing and notes',
      'recipient_name_edit': 'Recipient Name',
      'recipient_name_edit_hint': 'Enter recipient name',
      'phone_number_edit': 'Phone Number',
      'phone_number_edit_hint': '+1 (555) 123-4567',
      'city_edit': 'City',
      'city_edit_hint': 'Enter city name',
      'delivery_address_edit': 'Delivery Address',
      'delivery_address_edit_hint': 'Enter complete address',
      'order_price_edit': 'Order Price',
      'order_price_edit_hint': '\$0.00',
      'special_notes': 'Special Notes (Optional)',
      'special_notes_hint': 'Any special instructions...',
      'save_changes_tooltip': 'Save Changes',
      'cancel_edit': 'Cancel',
      'update_order_button': 'Update Order',
      'order_update_success': 'Order Updated Successfully!',
      'order_update_success_desc': 'Your changes have been saved and updated.',
      'back_to_orders': 'Back to Orders',
      
      // Edit Order Validation Messages
      'name_required_edit': 'Name is required',
      'phone_required_edit': 'Phone number is required',
      'city_required_edit': 'City is required',
      'address_required_edit': 'Address is required',
      'price_required_edit': 'Price is required',
      
      // History Page
      'order_history': 'Order History',
      'delivery_history_page': 'Delivery History',
      'filter_by': 'Filter By',
      'all_orders': 'All Orders',
      'completed_status': 'Completed',
      'in_progress': 'In Progress',
      'search_orders': 'Search Orders',
      'date_range': 'Date Range',
      'from_date': 'From Date',
      'to_date': 'To Date',
      'apply_filter': 'Apply Filter',
      'clear_filter': 'Clear Filter',
      'export_data': 'Export Data',
      'total_earnings': 'Total Earnings',
      'average_rating': 'Average Rating',
      'total_distance': 'Total Distance',
      'sort_by': 'Sort By',
      'date_newest': 'Date (Newest)',
      'date_oldest': 'Date (Oldest)',
      'amount_highest': 'Amount (Highest)',
      'amount_lowest': 'Amount (Lowest)',
      
      // Profile Page Elements
      'my_profile': 'My Profile',
      'personal_info': 'Personal Information',
      'edit_profile': 'Edit Profile',
      'save_changes_btn': 'Save Changes',
      'account_settings': 'Account Settings',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'notification_settings': 'Notification Settings',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'sms_notifications': 'SMS Notifications',
      'order_updates': 'Order Updates',
      'promotional_offers': 'Promotional Offers',
      'privacy_settings': 'Privacy Settings',
      'share_location': 'Share Location',
      'profile_visibility': 'Profile Visibility',
      'data_usage': 'Data Usage',
      'logout': 'Logout',
      'delete_account': 'Delete Account',
      'about_app': 'About App',
      'app_version': 'App Version',
      'terms_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'help_support_menu': 'Help & Support',
      'rate_app': 'Rate App',
      'profile_updated_successfully': 'Profile updated successfully',
      'password_changed_successfully': 'Password changed successfully',
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'are_you_sure_delete_account': 'Are you sure you want to delete your account?',
      
      // Additional Profile Elements
      'ice_number': 'ICE Number',
      'cne_number': 'CNE Number',
      'update_avatar': 'Update Avatar',
      'choose_method': 'Choose method',
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      'change_password_btn': 'Change',
      'account_section': 'Account',
      'support_section': 'Support',
      'help_and_support': 'Help & Support',
      'get_help_with_orders': 'Get help with your orders',
      'about_section': 'About',
      'app_version_info': 'App version and information',
      'sign_out_account': 'Sign out of your account',
      'update_personal_info': 'Update your personal information',
      'update_account_password': 'Update your account password',
      'manage_payment_options': 'Manage your payment options',
      'payment_methods': 'Payment Methods',
      'receive_order_updates': 'Receive order updates',
      'switch_to_dark_theme': 'Switch to dark theme',
      'no_email': 'No email',
      'user_fallback': 'User',
      
      // Validation Messages
      'first_name_min_chars': 'First name must be at least 2 characters',
      'last_name_min_chars': 'Last name must be at least 2 characters',
      'ice_min_chars': 'ICE number must be at least 3 characters',
      'rib_min_chars': 'RIB must be at least 10 characters',
      'cne_min_chars': 'CNE number must be at least 8 characters',
      'company_min_chars': 'Company name must be at least 2 characters',
      'website_must_start_http': 'Website must start with http:// or https://',
      'website_url_invalid': 'Website URL must be valid',
      'at_least_one_field': 'At least one field must be filled',
      'enter_current_password': 'Please enter your current password',
      'enter_new_password': 'Please enter a new password',
      'passwords_dont_match': 'Passwords don\'t match',
      'new_password_min_chars': 'New password must be at least 6 characters',
      'profile_update_success': 'Profile updated successfully!',
      'profile_update_failed': 'Failed to update profile',
      'password_change_success': 'Password changed successfully!',
      'password_change_failed': 'Failed to change password',
      'avatar_updated_success': 'Avatar updated successfully!',
      'avatar_update_failed': 'Failed to update avatar',
      'notifications_updated': 'Notification preferences updated',
      'dark_mode_enabled': '🌙 Dark mode enabled!',
      'light_mode_enabled': '☀️ Light mode enabled!',
      'language_changed_to': 'Language changed to',
      'opening_help_center': 'Opening help center...',
      'payment_methods_coming_soon': 'Payment methods feature coming soon!',
      'failed_load_profile': 'Failed to load profile',
      'view_action': 'View',
      
      // Login Page - Register Link
      'dont_have_account_login': 'Don\'t have an account?',
      'register_here': 'Register here',
      'forgot_password': 'Forgot Password?',
      'remember_me': 'Remember Me',
      
      // Contact Form Elements
      'subject': 'Subject',
      'subject_hint': 'Enter subject',
      'your_message': 'Your Message',
      'send_now': 'Send Now',
      'contact_info': 'Contact Information',
      'our_address': 'Our Address',
      'call_us': 'Call Us',
      'email_us': 'Email Us',
      'business_hours': 'Business Hours',
      'monday_friday': 'Monday - Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'closed': 'Closed',
      
      // Additional order details translations
      'order_details_title': 'Order Details',
      'close_button': 'Close',
      'tracking_info_section': 'Tracking Information',
      'customer_info_section': 'Customer Information',
      'order_summary_section': 'Order Summary',
      'print_invoice_button': 'Print Invoice',
      'print_button': 'Print',
      'cancel_button': 'Cancel',
      'generate_invoice_dialog': 'Generate and print invoice for order',
      'generating_invoice_text': 'Generating invoice...',
      'invoice_success_prefix': 'Invoice for',
      'invoice_success_suffix': 'sent to printer',
      
      // Overview and Analytics translations (only new unique keys)
      'recent_activity': 'Recent Activity',
      'performance_analytics': 'Performance Analytics',
      'average_delivery_time': 'Average Delivery Time',
      'customer_satisfaction': 'Customer Satisfaction',
      'total_revenue': 'Total Revenue',
      'delivery_statistics': 'Delivery Statistics',
      'overview': 'Overview',
      'analytics': 'Analytics',
      'tracking_id': 'Tracking ID',
      'delivery_time': 'Delivery Time',
      'recipient': 'Recipient',
      'to_prefix': 'To:',

      //elkadn1
      'searchDrivers': 'Search drivers...',
      'searchCustomers': 'Search customers...',
      'searchAdmins': 'Search admins...',
      'sendEmail': 'Send Email',
      'emailAddress': 'Email Address',
      'copyEmailMessage': 'You can copy the email address to use it in your preferred email app.',
      'copyEmail': 'Copy Email',
      'emailCopied': 'Email Copied',
      'contactMessages': 'Contact Messages',
      'openAnyway': 'Open Anyway',
      'number': 'Number',
      'phoneAppWillOpen': 'The phone app will open with this number pre-filled.',
      'sortAscending': 'Sort Ascending',
      'sortDescending': 'Sort Descending',
      'switchToLightMode': 'Switch to Light Mode',
      'switchToDarkMode': 'Switch to Dark Mode',
      'searchMessages': 'Search messages...',
      'noMessagesFound': 'No messages found',
      'messageDeletedSuccessfully': 'Message deleted successfully',
      'deleteMessageConfirm': 'Do you really want to delete the message from',
      'call': 'Call',
      'cannotMakePhoneCall': "Cannot make a phone call",
      'cannotOpenWhatsApp': "Cannot open WhatsApp",
      'sortOldestFirst': 'Sort oldest first',
      'sortNewestFirst': 'Sort newest first',
      'no_city_found' : 'No cities found',
      'search_cities': 'Search cities ...',
      'updated': 'Updated',
      'description_optional': 'Description (Optional)',
      'please_enter_city_name': 'Please enter a city name',
      'city_name': 'City Name',
      'add_city': 'Add City',
      'edit_city': 'Edit City',
      'city_deleted_successfully': 'City deleted successfully',
      'cannot_delete_city': 'Cannot delete city. It is being used in orders.',
      'city_updated_successfully': 'City updated successfully',
      'city_name_exists': 'City name already exists',
      'city_created_successfully': 'City created successfully',
      'delete_city_confirm': 'Delete City Confirmation',
      'cities_page': 'Cities Page',
      'contacts_page': 'Contacts Page',
      'cities_management': 'Cities Management',
      'edit_driver': 'Edit Driver',
      'noStatusHistory': 'No Status History',
      'insufficientPermissions': 'Insufficient permissions',
      'accessDenied': 'Access denied',
      'please_select_city': 'Please select a city',
      'changeCity': 'Change City',
      'commission': 'Commission',
      'currentCity': 'Current City',
      'print': 'Print',
      'label_printed_success': 'Label printed successfully',
      'currentStatus' : 'Current Status',
      'select_new_status': 'Select New Status',
      'assign_or_change_driver': 'Assign or change delivery driver',
      'updating_status': 'Updating status...',
      'note_optional': 'Note (optional)',
      'select_status': 'Select Status',
      'update_order_status': 'Update Order Status',
      'selection_required': 'Selection required',
      'please_select_driver': 'Please select a driver',
      'ok': 'OK',
      'driver_assigned_success': 'Driver assigned successfully',
      'driver_assignment_failed': 'Driver assignment failed',
      'assign_driver': 'Assign a driver',
      'no_driver_available': 'No driver available',
      'select_driver': 'Select a driver',
      'assign': 'Assign',
      'sender': 'Sender',
      'driver': 'Driver',
      'nonAssigned': 'Not assigned',
      'customer_created_success': 'Customer created successfully !',
      'driver_created_success': 'Driver created successfully !',
      'server_timeout': 'The server took too long to respond !',
      'order_actions': 'Order Actions',
      'tracking_view_details': 'Tracking: View Details',
      'confirm_order': 'Confirm Order',

      'shipment_list': 'Shipment List',
      'no_orders_yet': 'No orders yet. Please wait for customer requests',

      "user_updated_successfully": "User updated successfully!",
      "add_new_customer": "Add New Customer",
      "add_new_driver": "Add New Driver",
      "edit_user_management": "Edit User Management",
      "edit_customer": "Edit Customer",
      "next": "Next",
      "previous": "Previous",
      "submit": "Submit",
      "user_status": "User Status",
      "newsletter_subscription": "Newsletter Subscription",
      "internal_notes": "Internal Notes",
      "Zip_Code": "Zip Code",
      'super_admins': 'Super Admins',
      'user_management': 'User Management',
      'drivers': 'Drivers',
      'customers': 'Customers',
      'home': 'Home',
      'users': 'Users',
      'no_super_admins_found': 'No super-admins found',
      'gender': 'Gender',
      'office': 'Office',
      'user_level': 'User Level',
      'created': 'Created',
      'not_specified': 'Not specified',
      'active': 'Active',
      'inactive': 'Inactive',
      'close': 'Close',
      'addresses_of': 'Addresses of',
      'no_address_found': 'No address found',
      'confirm_deletion': 'Confirm deletion',
      'delete_user_confirm': 'Are you sure you want to delete',
      'delete': 'Delete',
      'user_deleted_success': 'User successfully deleted',
      'error_deleting_user': 'Error while deleting',
      'error_fetching_addresses': 'Error fetching addresses',
      'no_user_management_found': 'No User Management found',
      'user_management_level': 'User Management (Level {level})',
      'no_drivers_found': 'No drivers found',
      'vehicle_code': 'Vehicle Code',
      'vehicle_registration_number': 'Vehicle Registration Number',
      'driver_level': 'Driver (Level {level})',
      'no_customers_found': 'No customers found',
      'document_type': 'Document Type',
      'document_number': 'Document Number',
      'customer_level': 'Customer (Level {level})',
      'add_new_user_management': 'Add New User Management',
      'personal': 'Personal',
      'username_required': 'Username is required',
      'first_name_required': 'First name is required',
      'last_name_required': 'Last name is required',
      'username_min_length': 'The username must contain at least 5 characters',
      'invalid_email': 'Please enter a valid email address',
      'address_required': 'At least one full address is required',
      'user_created_success': 'User created successfully',
      'no_addresses_found': 'No addresses found. Add at least one address.',
      'add_another_address': 'Add Another Address',
      'leave_password_empty': 'Leave password empty to keep current password',
      'select_Office': 'Select an office',
      'select_user_level' : 'Select User Level',
      'Country': 'country',

    },
    'fr': {
      // Existing keys (keeping all previous French translations)
      'app_title': 'YanShip Livraison',
      'driver_home': 'Accueil Chauffeur',
      'orders': 'Commandes',
      'new_order': 'Nouvelle Commande',
      'order_details': 'Détails de la Commande',
      'order_status': 'Statut de la Commande',
      'order_id': 'ID de Commande',
      'customer_name': 'Nom du Client',
      'delivery_address': 'Adresse de Livraison',
      'phone_number': 'Numéro de Téléphone',
      'order_total': 'Total de la Commande',
      'accept_order': 'Accepter la Commande',
      'decline_order': 'Refuser la Commande',
      'mark_delivered': 'Marquer comme Livré',
      'mark_picked_up': 'Marquer comme Récupéré',
      'pending': 'En Attente',
      'accepted': 'Accepté',
      'picked_up': 'Récupéré',
      'delivered': 'Livré',
      'cancelled': 'Annulé',
      'settings': 'Paramètres',
      'language': 'Langue',
      'theme': 'Thème',
      'light_mode': 'Mode Clair',
      'dark_mode': 'Mode Sombre',
      'system_mode': 'Mode Système',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'notification_title': 'Mise à jour du Statut',
      'order_accepted': 'Commande acceptée',
      'order_picked_up': 'Commande récupérée',
      'order_delivered': 'Commande livrée',
      'order_cancelled': 'Commande annulée',
      'confirm_delivery': 'Confirmer la Livraison',
      
      // Authentication & Welcome page keys in French
      'welcome': 'Bienvenue',
      'skip': 'Passer',
      'login': 'Connexion',
      'sign_in': 'Se Connecter',
      'register': 'S\'inscrire',
      'sign_up': 'Créer un Compte',
      'create_account': 'Créer un Compte',
      'email_label': 'Email',
      'password_label': 'Mot de Passe',
      'confirm_password_label': 'Confirmer le Mot de Passe',
      'first_name_label': 'Prénom',
      'last_name_label': 'Nom',
      'username_label': 'Nom d\'utilisateur',
      'phone_label': 'Téléphone',
      'address_label': 'Adresse',
      'city_label': 'Ville',
      'company_label': 'Entreprise',
      'already_have_account': 'Vous avez déjà un compte?',
      'dont_have_account': 'Vous n\'avez pas de compte?',
      'please_enter_email_auth': 'Veuillez saisir votre email',
      'please_enter_password_auth': 'Veuillez saisir votre mot de passe',
      'please_enter_first_name_auth': 'Veuillez saisir le prénom',
      'please_enter_last_name_auth': 'Veuillez saisir le nom',
      'please_enter_username_auth': 'Veuillez saisir le nom d\'utilisateur',
      'please_enter_phone_auth': 'Veuillez saisir le numéro de téléphone',
      'please_enter_address_auth': 'Veuillez saisir l\'adresse',
      'please_enter_city_auth': 'Veuillez saisir la ville',
      'password_min_length_auth': 'Le mot de passe doit contenir au moins 6 caractères',
      'passwords_not_match_auth': 'Les mots de passe ne correspondent pas',
      'login_success': 'Connexion réussie',
      'register_success': 'Inscription réussie',
      'login_failed': 'Échec de la connexion',
      'register_failed': 'Échec de l\'inscription',
      'are_you_sure_delivery': 'Êtes-vous sûr de vouloir marquer cette commande comme livrée?',
      'yes': 'Oui',
      'no': 'Non',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'error': 'Erreur',
      'success': 'Succès',
      'loading': 'Chargement...',
      'no_orders': 'Aucune commande disponible',
      'retry': 'Réessayer',
      'refresh': 'Rafraîchir',
      'changeStatus': 'Changer le statut',
      'uploadProof': 'Télécharger la preuve',
      'generateInvoice': 'Générer une facture',
      // Dashboard keys
      'dashboard': 'Tableau de Bord',
      'driver_dashboard': 'Tableau de Bord Chauffeur',
      'driver_id': 'ID Chauffeur',
      'total_orders': 'Total Commandes',
      'returned': 'Retournées',
      'performance_overview': 'Aperçu des Performances',
      'success_rate': 'Taux de Réussite',
      'earnings': 'Revenus',
      'delivered_orders': 'Commandes Livrées',
      'delivered_amount': 'Gains du Livreur (MAD)',
      'average_ticket': 'Ticket Moyen',
      'pending_invoices': 'Factures en Attente',
      
      // Order Details keys
      'order_information': 'Informations de Commande',
      'order_no': 'No de Commande',
      'order_encoded': 'Commande Encodée',
      'order_date': 'Date de Commande',
      'customer_information': 'Informations Client',
      'receiver_name': 'Nom du Destinataire',
      'person_receives': 'Personne qui Reçoit',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'city': 'Ville',
      'payment_information': 'Informations de Paiement',
      'price': 'Prix',
      'price_after_fee': 'Prix Après Frais',
      'to': 'À',
      'order_timeline': 'Chronologie de la Commande',
      'no_timeline_events': 'Aucun événement chronologique',
      'notes': 'Notes',
      'print_label': 'Imprimer Étiquette',
      'generate_shipping_label': 'Générer étiquette d\'expédition',
      
      // Order card and action keys
      'confirm_order_dialog_title': 'Confirmer la Commande',
      'confirm_order_dialog_message': 'Cela changera le statut en "Confirmé" et la commande sera prête pour la collecte.',
      'failed_to_confirm_order': 'Échec de la confirmation de la commande',
      'editable': 'Modifiable',
      'na': 'N/D',
      'modify_order_details': 'Modifier les détails de la commande',
      'show_delivery_information': 'Afficher les informations de livraison',
      'mark_confirmed_ready': 'Marquer comme confirmé et prêt',
      'delete_order_permanently': 'Supprimer la commande définitivement',
      'orders_picked_up_successfully': 'commandes récupérées avec succès',
      'failed_to_pickup_orders': 'Échec de la récupération des commandes',
      'order_confirmed_successfully': 'a été confirmée avec succès',
      'failed_to_cancel_order': 'Échec de l\'annulation de la commande',
      'order': 'Commande',
      'error_picking_up_orders': 'Erreur lors de la récupération des commandes',
      'error_order_id_not_found': 'Erreur : ID de commande non trouvé',
      'error_cancelling_order': 'Erreur lors de l\'annulation de la commande',
      'error_tracking_number_not_found': 'Erreur : Numéro de suivi non trouvé',
      'error_confirming_order': 'Erreur lors de la confirmation de la commande',
      'error_loading_orders': 'Erreur lors du chargement des commandes',
      'recipient_name': 'Destinataire',
      'no_phone_number': 'Aucun numéro de téléphone',
      'no_address': 'Aucune adresse',
      'status_history': 'Historique du statut',
      'delivery_status': 'Statut de Livraison',
      'completed': 'Terminé',
      'proof_uploaded': 'Preuve Téléchargée',
      'proof_file': 'Fichier de Preuve',
      'invoice_status': 'Statut de Facture',
      'generated': 'Généré',
      'not_generated': 'Non Généré',
      'status_note': 'Note de Statut',
      'status_cannot_change': 'Ce statut ne peut pas être changé',
      'locked': 'Verrouillé',
      
      // HomePage specific keys
      'all': 'Tout',
      'unknown': 'Inconnu',
      'print_bon_reception': 'Imprimer Bon de Réception',
      'unknown_city': 'Ville Inconnue',
      'status_created': 'Créé',
      'status_confirmed': 'Confirmé',
      'status_in_transit': 'En Transit',
      'status_picked_up': 'Récupéré',
      'status_out_for_delivery': 'En Livraison',
      'status_attempted_delivery': 'Tentative de Livraison',
      'status_delivered': 'Livré',
      'status_returned': 'Retourné',
      'status_cancelled': 'Annulé',
      'status_rejected': 'Rejeté',
      
      // Profile keys
      'profile': 'Profil',
      'personal_information': 'Informations Personnelles',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'email': 'Email',
      'username': 'Nom d\'utilisateur',
      'rib': 'RIB',
      'cne': 'CNE',
      'ice': 'ICE',
      'last_login': 'Dernière Connexion',
      'registration_date': 'Date d\'inscription',
      'password': 'Mot de Passe',
      'confirm_password': 'Confirmer Mot de Passe',
      'save_changes': 'Sauvegarder les Modifications',
      'profile_updated_success': 'Profil mis à jour avec succès',
      'please_enter_first_name': 'Veuillez entrer le prénom',
      'please_enter_last_name': 'Veuillez entrer le nom',
      'please_enter_email': 'Veuillez entrer l\'email',
      'please_enter_valid_email': 'Veuillez entrer un email valide',
      'please_enter_username': 'Veuillez entrer le nom d\'utilisateur',
      'please_enter_rib': 'Veuillez entrer le RIB',
      'please_enter_cne': 'Veuillez entrer le CNE',
      'please_enter_ice': 'Veuillez entrer l\'ICE',
      'please_enter_phone': 'Veuillez entrer le numéro de téléphone',
      'please_enter_address': 'Veuillez entrer l\'adresse',
      'please_enter_city': 'Veuillez entrer la ville',
      'password_min_length': 'Le mot de passe doit contenir au moins 6 caractères',
      'passwords_not_match': 'Les mots de passe ne correspondent pas',
      'rating': 'Évaluation',
      'connection_error': 'Erreur de connexion au serveur',

      // Help & Support keys in French
      'help_support': 'Aide et Support',
      'emergency_support': 'Support d\'Urgence',
      'emergency_support_desc': 'Pour les problèmes de livraison urgents ou les urgences',
      'call_now': 'Appeler Maintenant',
      'whatsapp': 'WhatsApp',
      'could_not_open_whatsapp': 'Impossible d\'ouvrir WhatsApp',
      'quick_actions': 'Actions Rapides',
      'driver_status': 'Statut Chauffeur',
      'driver_status_desc': 'Mettre à jour la disponibilité, paramètres de localisation',
      'delivery_history': 'Historique des Livraisons',
      'delivery_history_desc': 'Voir les livraisons passées et les revenus',
      'payment_info': 'Informations de Paiement',
      'payment_info_desc': 'Vérifier les revenus et les méthodes de paiement',
      'opening_driver_status': 'Ouverture du statut chauffeur...',
      'opening_delivery_history': 'Ouverture de l\'historique des livraisons...',
      'opening_payment_info': 'Ouverture des informations de paiement...',
      'submit_support_request': 'Soumettre une Demande de Support',
      'issue_type': 'Type de Problème',
      'technical_issue': 'Problème Technique',
      'technical_issue_desc': 'Plantages d\'app, problèmes de connexion, problèmes GPS',
      'delivery_problem': 'Problème de Livraison',
      'delivery_problem_desc': 'Impossible de trouver l\'adresse, client indisponible',
      'payment_issue': 'Problème de Paiement',
      'payment_issue_desc': 'Paiements manqués, montants incorrects',
      'account_problem': 'Problème de Compte',
      'account_problem_desc': 'Mises à jour de profil, problèmes de vérification',
      'other': 'Autre',
      'other_desc': 'Questions générales ou autres préoccupations',
      'describe_issue': 'Décrire le Problème',
      'describe_issue_placeholder': 'Veuillez décrire votre problème en détail...',
      'please_describe_issue': 'Veuillez décrire votre problème',
      'provide_more_details': 'Veuillez fournir plus de détails (au moins 10 caractères)',
      'submit_request': 'Soumettre la Demande',
      'support_request_success': 'Demande de support soumise avec succès! Nous vous recontacterons bientôt.',
      'frequently_asked_questions': 'Questions Fréquemment Posées',
      'faq_gps_title': 'Le GPS ne fonctionne pas correctement',
      'faq_gps_answer': 'Essayez d\'activer les services de localisation dans les paramètres de votre appareil, redémarrez l\'app, ou vérifiez si vous avez la dernière version de l\'app installée.',
      'faq_payment_title': 'Quand vais-je recevoir mon paiement?',
      'faq_payment_answer': 'Les paiements sont traités chaque vendredi. Vous devriez recevoir vos revenus dans les 2-3 jours ouvrables après le traitement.',
      'faq_customer_title': 'Le client n\'est pas disponible',
      'faq_customer_answer': 'Essayez d\'abord d\'appeler le client. Si pas de réponse, attendez 5 minutes et réessayez. Après 15 minutes, vous pouvez marquer comme "tentative de livraison" et retourner le colis.',

      // Invoice keys in French - ADDED
      'invoices': 'Factures',
      'invoice_no': 'N° de facture',
      'date': 'Date',
      'amount': 'Montant',
      'status': 'Statut',
      'download': 'Télécharger',
      'view': 'Voir',
      'coming_soon': 'Bientôt disponible !',
      'no_invoices_found': 'Aucune facture trouvée',
      'paid': 'Payée',
      'history': 'Historique',
      
      // Welcome page specific keys in French
      'app_name': 'Yanship',
      'light_mode_tooltip': 'Mode clair',
      'dark_mode_tooltip': 'Mode sombre',
      'we_are_yanship': 'Nous sommes Yan Ship',
      'yanship_description': 'Nous sommes ici en tant que partenaire, nous avons besoin que vous gagniez plus car votre gain est aussi le nôtre, nous offrons un service de livraison et nous vous suggérons un pack complet des fournisseurs à la livraison sans passer de temps là-dessus pour rester concentré sur la croissance. C\'est pourquoi vous pouvez nous appeler votre extension d\'entreprise.',
      'features': 'Fonctionnalités',
      'feature_description': 'Découvrez nos solutions de livraison complètes',
      'fast_delivery': 'Livraison Rapide',
      'secure_payment': 'Paiement Sécurisé',
      'real_time_tracking': 'Suivi en Temps Réel',
      'all_in_one_pack': 'Nous offrons un pack tout-en-un',
      'all_in_one_pack_desc': 'Pas besoin de se distraire entre beaucoup de services, nous vous donnons un pack complet. Il suffit de l\'étendre !',
      'fast_shipping': 'Expédition rapide',
      'fast_shipping_desc': 'Notre temps de livraison dans tout le Maroc avec un temps moyen de 24H. Yalla !',
      'payment_24h': 'Paiement 24H',
      'payment_24h_desc': 'Nous envoyons les paiements quotidiennement donc il n\'y a pas de retard de flux de trésorerie. Sonnerie d\'argent !',
      'pricing': 'Tarification',
      'choose_plan': 'Choisissez Votre Plan',
      'silver': 'Argent',
      'gold': 'Or',
      'platinum': 'Platine',
      'month': '/mois',
      'basic_features': 'Fonctionnalités de livraison de base',
      'advanced_features': 'Fonctionnalités avancées + support prioritaire',
      'premium_features': 'Toutes les fonctionnalités + support premium',
      'contact_us': 'Contactez-nous',
      'get_in_touch': 'Restons en Contact',
      'contact_description': 'Vous avez des questions? Nous aimerions avoir de vos nouvelles.',
      'name': 'Nom',
      'name_hint': 'Entrez votre nom',
      'email_hint': 'Entrez votre email',
      'phone_hint': 'Entrez votre numéro de téléphone',
      'message': 'Message',
      'message_hint': 'Entrez votre message',
      'send_message': 'Envoyer le Message',
      'name_required': 'Le nom est requis',
      'email_required': 'L\'email est requis',
      'email_invalid': 'Veuillez entrer un email valide',
      'phone_required': 'Le numéro de téléphone est requis',
      'message_required': 'Le message est requis',
      'message_sent': 'Message envoyé avec succès!',
      'message_error': 'Échec de l\'envoi du message. Veuillez réessayer.',
      
      // VIP Plans and Pricing
      'vip_plans': 'Plans VIP',
      'choose_your_plan': 'Choisissez votre plan',
      'most_popular': 'Le plus populaire',
      'per_month': 'par mois',
      'get_started': 'Commencer',
      'select_plan': 'Sélectionner le plan',
      'free_trial': 'Essai gratuit',
      'unlimited_deliveries': 'Livraisons illimitées',
      'priority_support_plan': 'Support prioritaire',
      'advanced_analytics': 'Analyses avancées',
      'custom_branding': 'Image de marque personnalisée',
      'api_access': 'Accès API',
      
      // Home Page Elements
      'welcome_back': 'Bon retour',
      'main_dashboard': 'Tableau de bord',
      'quick_stats': 'Statistiques rapides',
      'total_deliveries': 'Total des livraisons',
      'completed_orders': 'Commandes terminées',
      'pending_orders': 'Commandes en attente',
      'earnings_today': 'Gains d\'aujourd\'hui',
      'recent_orders': 'Commandes récentes',
      'view_all_orders': 'Voir toutes les commandes',
      'no_recent_orders': 'Aucune commande récente',
      'quick_actions_home': 'Actions rapides',
      'new_delivery': 'Nouvelle livraison',
      'track_package': 'Suivre le colis',
      'customer_support': 'Service client',
      'performance': 'Performance',
      'this_week': 'Cette semaine',
      'this_month': 'Ce mois',
      'delivery_rate': 'Taux de livraison',
      'customer_rating': 'Note client',
      'on_time_delivery': 'Livraison à temps',
      
      // Create Order Page
      'create_new_order': 'Créer une nouvelle commande',
      'customer_info': 'Informations client',
      'customer_name_field': 'Nom du client',
      'customer_phone': 'Téléphone du client',
      'customer_email': 'Email du client',
      'delivery_info': 'Informations de livraison',
      'pickup_address': 'Adresse de collecte',
      'delivery_address_field': 'Adresse de livraison',
      'delivery_notes': 'Notes de livraison',
      'package_details': 'Détails du colis',
      'package_description': 'Description du colis',
      'package_weight': 'Poids du colis',
      'package_dimensions': 'Dimensions du colis',
      'fragile_item': 'Article fragile',
      'express_delivery': 'Livraison express',
      'delivery_fee': 'Frais de livraison',
      'total_amount': 'Montant total',
      'payment_method': 'Mode de paiement',
      'cash_on_delivery': 'Paiement à la livraison',
      'prepaid': 'Prépayé',
      'create_order_btn': 'Créer la commande',
      'order_created_successfully': 'Commande créée avec succès',
      'please_fill_required_fields': 'Veuillez remplir tous les champs requis',
      
      // Create Order Page Additional Fields
      'create_order_page_title': 'Créer une nouvelle commande',
      'create_order_description': 'Remplissez tous les détails ci-dessous pour créer votre commande de livraison',
      'recipient_name_field': 'Nom du destinataire',
      'recipient_name_hint': 'Entrez le nom complet',
      'phone_number_field': 'Numéro de téléphone',
      'phone_number_hint': '+33 1 23 45 67 89',
      'city_field': 'Ville',
      'city_hint': 'Entrez la ville',
      'delivery_address_field_label': 'Adresse de livraison',
      'delivery_address_hint': 'Entrez l\'adresse complète de livraison',
      'order_price_field': 'Prix de la commande',
      'order_price_hint': '0,00 €',
      'authorize_open_package': 'Autoriser l\'ouverture du colis',
      'authorize_open_package_description': 'Cochez cette case si vous autorisez le livreur à ouvrir le colis à des fins de vérification',
      
      // Form Validation Messages
      'name_required_error': 'Le nom est requis',
      'phone_required_error': 'Le numéro de téléphone est requis',
      'city_required_error': 'La ville est requise',
      'delivery_address_required_error': 'L\'adresse de livraison est requise',
      'price_required_error': 'Le prix est requis',
      'valid_price_required_error': 'Entrez un prix valide',
      
      // Error Messages
      'order_creation_failed': 'Échec de la création de la commande',
      'try_again_button': 'Réessayer',
      
      // Success Dialog Messages
      'order_success_description': 'Votre commande de livraison a été créée et sera traitée sous peu. Vous recevrez des mises à jour via les notifications.',
      'create_another_order': 'Créer une autre',
      'back_to_home': 'Retour à l\'accueil',
      
      // Edit Order Page
      'edit_order': 'Modifier la commande',
      'update_order': 'Mettre à jour la commande',
      'order_updated_successfully': 'Commande mise à jour avec succès',
      'cancel_order': 'Annuler la commande',
      'order_cancelled_successfully': 'Commande annulée avec succès',
      'are_you_sure_cancel': 'Êtes-vous sûr de vouloir annuler cette commande?',
      'order_info': 'Informations de commande',
      'tracking_number': 'Numéro de suivi',
      'order_date_field': 'Date de commande',
      'estimated_delivery': 'Livraison estimée',
      'actual_delivery': 'Livraison réelle',
      'delivery_proof': 'Preuve de livraison',
      'upload_proof': 'Télécharger la preuve',
      'add_note': 'Ajouter une note',
      'order_notes': 'Notes de commande',
      
      // Edit Order Page Additional Fields
      'edit_order_title': 'Modifier la commande',
      'edit_order_subtitle': 'Apporter des modifications aux détails de la commande',
      'customer_info_edit_section': 'Informations client',
      'customer_info_edit_subtitle': 'Mettre à jour les détails du destinataire',
      'delivery_info_edit_section': 'Informations de livraison',
      'delivery_info_edit_subtitle': 'Mettre à jour l\'adresse de livraison',
      'order_details_edit_section': 'Détails de la commande',
      'order_details_edit_subtitle': 'Mettre à jour les prix et les notes',
      'recipient_name_edit': 'Nom du destinataire',
      'recipient_name_edit_hint': 'Entrez le nom du destinataire',
      'phone_number_edit': 'Numéro de téléphone',
      'phone_number_edit_hint': '+33 1 23 45 67 89',
      'city_edit': 'Ville',
      'city_edit_hint': 'Entrez le nom de la ville',
      'delivery_address_edit': 'Adresse de livraison',
      'delivery_address_edit_hint': 'Entrez l\'adresse complète',
      'order_price_edit': 'Prix de la commande',
      'order_price_edit_hint': '0,00 €',
      'special_notes': 'Notes spéciales (Optionnel)',
      'special_notes_hint': 'Instructions spéciales...',
      'save_changes_tooltip': 'Enregistrer les modifications',
      'cancel_edit': 'Annuler',
      'update_order_button': 'Mettre à jour la commande',
      'order_update_success': 'Commande mise à jour avec succès!',
      'order_update_success_desc': 'Vos modifications ont été enregistrées et mises à jour.',
      'back_to_orders': 'Retour aux commandes',
      
      // Edit Order Validation Messages
      'name_required_edit': 'Le nom est requis',
      'phone_required_edit': 'Le numéro de téléphone est requis',
      'city_required_edit': 'La ville est requise',
      'address_required_edit': 'L\'adresse est requise',
      'price_required_edit': 'Le prix est requis',
      
      // History Page
      'order_history': 'Historique des commandes',
      'delivery_history_page': 'Historique des livraisons',
      'filter_by': 'Filtrer par',
      'all_orders': 'Toutes les commandes',
      'completed_status': 'Terminé',
      'in_progress': 'En cours',
      'search_orders': 'Rechercher des commandes',
      'date_range': 'Plage de dates',
      'from_date': 'Date de début',
      'to_date': 'Date de fin',
      'apply_filter': 'Appliquer le filtre',
      'clear_filter': 'Effacer le filtre',
      'export_data': 'Exporter les données',
      'total_earnings': 'Gains totaux',
      'average_rating': 'Note moyenne',
      'total_distance': 'Distance totale',
      'sort_by': 'Trier par',
      'date_newest': 'Date (Plus récent)',
      'date_oldest': 'Date (Plus ancien)',
      'amount_highest': 'Montant (Le plus élevé)',
      'amount_lowest': 'Montant (Le plus bas)',
      
      // Profile Page Elements
      'my_profile': 'Mon profil',
      'personal_info': 'Informations personnelles',
      'edit_profile': 'Modifier le profil',
      'save_changes_btn': 'Enregistrer les modifications',
      'account_settings': 'Paramètres du compte',
      'change_password': 'Changer le mot de passe',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'confirm_new_password': 'Confirmer le nouveau mot de passe',
      'notification_settings': 'Paramètres de notification',
      'push_notifications': 'Notifications push',
      'email_notifications': 'Notifications par email',
      'sms_notifications': 'Notifications SMS',
      'order_updates': 'Mises à jour de commande',
      'promotional_offers': 'Offres promotionnelles',
      'privacy_settings': 'Paramètres de confidentialité',
      'share_location': 'Partager la localisation',
      'profile_visibility': 'Visibilité du profil',
      'data_usage': 'Utilisation des données',
      'logout': 'Se déconnecter',
      'delete_account': 'Supprimer le compte',
      'about_app': 'À propos de l\'app',
      'app_version': 'Version de l\'app',
      'terms_conditions': 'Termes et conditions',
      'privacy_policy': 'Politique de confidentialité',
      'help_support_menu': 'Aide et support',
      'rate_app': 'Évaluer l\'app',
      'profile_updated_successfully': 'Profil mis à jour avec succès',
      'password_changed_successfully': 'Mot de passe changé avec succès',
      'are_you_sure_logout': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'are_you_sure_delete_account': 'Êtes-vous sûr de vouloir supprimer votre compte?',
      
      // Login Page - Register Link
      'dont_have_account_login': 'Vous n\'avez pas de compte?',
      'register_here': 'S\'inscrire ici',
      'forgot_password': 'Mot de passe oublié?',
      'remember_me': 'Se souvenir de moi',
      
      // Contact Form Elements
      'subject': 'Sujet',
      'subject_hint': 'Entrez le sujet',
      'your_message': 'Votre message',
      'send_now': 'Envoyer maintenant',
      'contact_info': 'Informations de contact',
      'our_address': 'Notre adresse',
      'call_us': 'Appelez-nous',
      'email_us': 'Envoyez-nous un email',
      'business_hours': 'Heures d\'ouverture',
      'monday_friday': 'Lundi - Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
      'closed': 'Fermé',
      
      // Additional Profile Elements - French
      'ice_number': 'Numéro ICE',
      'cne_number': 'Numéro CNE',
      'update_avatar': 'Mettre à jour l\'avatar',
      'choose_method': 'Choisir la méthode',
      'take_photo': 'Prendre une photo',
      'choose_from_gallery': 'Choisir dans la galerie',
      'change_password_btn': 'Modifier',
      'account_section': 'Compte',
      'support_section': 'Support',
      'help_and_support': 'Aide et Support',
      'get_help_with_orders': 'Obtenez de l\'aide avec vos commandes',
      'about_section': 'À propos',
      'app_version_info': 'Version et informations de l\'application',
      'sign_out_account': 'Se déconnecter du compte',
      'update_personal_info': 'Mettre à jour vos informations personnelles',
      'update_account_password': 'Mettre à jour le mot de passe du compte',
      'manage_payment_options': 'Gérer vos options de paiement',
      'payment_methods': 'Moyens de paiement',
      'receive_order_updates': 'Recevoir les mises à jour de commande',
      'switch_to_dark_theme': 'Passer au thème sombre',
      'no_email': 'Aucun email',
      'user_fallback': 'Utilisateur',



      
      // Validation Messages - French
      'first_name_min_chars': 'Le prénom doit contenir au moins 2 caractères',
      'last_name_min_chars': 'Le nom de famille doit contenir au moins 2 caractères',
      'ice_min_chars': 'Le numéro ICE doit contenir au moins 3 caractères',
      'rib_min_chars': 'Le RIB doit contenir au moins 10 caractères',
      'cne_min_chars': 'Le numéro CNE doit contenir au moins 8 caractères',
      'company_min_chars': 'Le nom de l\'entreprise doit contenir au moins 2 caractères',
      'website_must_start_http': 'Le site web doit commencer par http:// ou https://',
      'website_url_invalid': 'L\'URL du site web doit être valide',
      'at_least_one_field': 'Au moins un champ doit être rempli',
      'enter_current_password': 'Veuillez entrer votre mot de passe actuel',
      'enter_new_password': 'Veuillez entrer un nouveau mot de passe',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',
      'new_password_min_chars': 'Le nouveau mot de passe doit contenir au moins 6 caractères',
      'profile_update_success': 'Profil mis à jour avec succès !',
      'profile_update_failed': 'Échec de la mise à jour du profil',
      'password_change_success': 'Mot de passe modifié avec succès !',
      'password_change_failed': 'Échec de la modification du mot de passe',
      'avatar_updated_success': 'Avatar mis à jour avec succès !',
      'avatar_update_failed': 'Échec de la mise à jour de l\'avatar',
      'notifications_updated': 'Préférences de notification mises à jour',
      'dark_mode_enabled': '🌙 Mode sombre activé !',
      'light_mode_enabled': '☀️ Mode clair activé !',
      'language_changed_to': 'Langue changée vers',
      'opening_help_center': 'Ouverture du centre d\'aide...',
      'payment_methods_coming_soon': 'Fonctionnalité des moyens de paiement bientôt disponible !',
      'failed_load_profile': 'Échec du chargement du profil',
      'view_action': 'Voir',
      
      // Additional order details translations
      'order_details_title': 'Détails de la commande',
      'close_button': 'Fermer',
      'tracking_info_section': 'Informations de suivi',
      'customer_info_section': 'Informations client',
      'order_summary_section': 'Résumé de la commande',
      'print_invoice_button': 'Imprimer la facture',
      'print_button': 'Imprimer',
      'cancel_button': 'Annuler',
      'generate_invoice_dialog': 'Générer et imprimer la facture pour la commande',
      'generating_invoice_text': 'Génération de la facture...',
      'invoice_success_prefix': 'Facture pour',
      'invoice_success_suffix': 'envoyée à l\'imprimante',
      
      // Overview and Analytics translations
      'recent_activity': 'Activité récente',
      'performance_analytics': 'Analyses de performance',
      'average_delivery_time': 'Temps de livraison moyen',
      'customer_satisfaction': 'Satisfaction client',
      'total_revenue': 'Revenus totaux',
      'delivery_statistics': 'Statistiques de livraison',
      'overview': 'Aperçu',
      'analytics': 'Analyses',
      'tracking_id': 'ID de suivi',
      'delivery_time': 'Heure de livraison',
      'recipient': 'Destinataire',
      'to_prefix': 'À :',


      //elkadn2
      'searchDrivers': 'Rechercher des chauffeurs...',
      'searchCustomers': 'Rechercher des clients...',
      'searchAdmins': 'Rechercher des administrateurs...',
      'sendEmail': 'Envoyer un email',
      'emailAddress': 'Adresse email',
      'copyEmailMessage': "Vous pouvez copier l'adresse email pour l'utiliser dans votre application email préférée.",
      'copyEmail': "Copier l'email",
      'emailCopied': 'Email copié',
      'contactMessages': 'Messages de contact',
      'openAnyway': 'Ouvrir quand même',
      'number': 'Numéro',
      'phoneAppWillOpen': "L'application téléphone s'ouvrira avec ce numéro pré-rempli.",
      'sortAscending': 'Trier par ordre croissant',
      'sortDescending': 'Trier par ordre décroissant',
      'switchToLightMode': 'Passer en mode clair',
      'switchToDarkMode': 'Passer en mode sombre',
      'searchMessages': 'Rechercher des messages...',
      'noMessagesFound': 'Aucun message trouvé',
      'messageDeletedSuccessfully': 'Message supprimé avec succès',
      'deleteMessageConfirm': 'Voulez-vous vraiment supprimer le message de',
      'call': 'Appeler',
      'cannotMakePhoneCall': "Impossible de passer un appel",
      'cannotOpenWhatsApp': "Impossible d'ouvrir WhatsApp",
      'sortOldestFirst': 'Trier du plus ancien au plus récent',
      'sortNewestFirst': 'Trier du plus récent au plus ancien',
      'no_city_found' : 'Aucune ville trouvée',
      'search_cities': 'Rechercher une ville ...',
      'description_optional': 'Description (Optionnelle)',
      'please_enter_city_name': 'Veuillez entrer un nom de ville',
      'city_name': 'Nom de la ville',
      'add_city': 'Ajouter une ville',
      'edit_city': 'Modifier la ville',
      'updated': 'Mis à jour',
      'city_deleted_successfully': 'Ville supprimée avec succès',
      'cannot_delete_city': 'Impossible de supprimer la ville. Elle est utilisée dans des commandes.',
      'city_updated_successfully': 'Ville mise à jour avec succès',
      'city_name_exists': 'Le nom de la ville existe déjà',
      'city_created_successfully': 'Ville créée avec succès',
      'delete_city_confirm': 'Confirmation de suppression de la ville',
      'cities_management': 'Gestion des villes',
      'edit_driver': 'Modifier le chauffeur',
      'cities_page': 'Page des villes',
      'contacts_page': 'Page des contacts',
      'noStatusHistory': 'Aucun historique de statut disponible',
      'insufficientPermissions': 'Permissions insuffisantes',
      'accessDenied': 'Accès refusé',
      'please_select_city': 'Veuillez sélectionner une ville',
      'changeCity': 'Changer la ville',
      'commission': 'Commission',
      'currentCity': 'Ville actuelle',
      'print': 'Imprimer',
      'label_printed_success': 'Étiquette imprimée avec succès',
      'currentStatus' : 'Statut actuel',

      'select_new_status': 'Sélectionner un nouveau statut',
      'assign_or_change_driver': 'Assigner ou changer le chauffeur',
      'updating_status': 'Mise à jour du statut...',
      'update_status': 'Mettre à jour le statut',
      'note_optional': 'Note (optionnelle)',
      'select_status': 'Sélectionner un statut',
      'update_order_status': 'Mettre à jour le statut de la commande',
      'selection_required': 'Sélection requise',
      'please_select_driver': 'Veuillez sélectionner un chauffeur',
      'ok': 'OK',
      'driver_assigned_success': 'Chauffeur assigné avec succès',
      'driver_assignment_failed': 'Échec de l\'assignation',
      'assign_driver': 'Assigner un chauffeur',
      'no_driver_available': 'Aucun chauffeur disponible',
      'select_driver': 'Sélectionner un chauffeur',
      'assign': 'Assigner',
      'driver': 'Livreur',
      'nonAssigned': 'Non assigné',

      'sender': 'Expéditeur',
      'customer_created_success': 'Client créé avec succès !',
      'driver_created_success': 'Livreur créé avec succès !',
      'server_timeout': 'Le serveur a mis trop de temps à répondre !',
      'order_actions': 'Actions de la Commande',
      'tracking_view_details': 'Suivi : Voir les Détails',
      'confirm_order': 'Confirmer la Commande',

      'no_orders_yet': 'Veuillez attendre les demandes des clients',

      'shipment_list': 'Liste des Expéditions',
      "user_updated_successfully": "Utilisateur mis à jour avec succès !",
      "add_new_customer": "Ajouter un nouveau client",
      "add_new_driver": "Ajouter un nouveau chauffeur",
      "edit_user_management": "Modifier la gestion des utilisateurs",
      "edit_customer": "Modifier le client",
      "next": "Suivant",
      "previous": "Précédent",
      "submit": "Soumettre",
      "user_status": "Statut de l’utilisateur",
      "newsletter_subscription": "Abonnement à la newsletter",
      "internal_notes": "Notes internes",
      "Zip_Code": "Code Postal",
      'no_super_admins_found': 'Aucun super-admin trouvé',
      'gender': 'Genre',
      'office': 'Bureau',
      'user_level': 'Niveau utilisateur',
      'created': 'Créé',
      'not_specified': 'Non spécifié',
      'active': 'Actif',
      'inactive': 'Inactif',
      'close': 'Fermer',
      'addresses_of': 'Adresses de',
      'no_address_found': 'Aucune adresse trouvée',
      'confirm_deletion': 'Confirmer la suppression',
      'delete_user_confirm': 'Êtes-vous sûr de vouloir supprimer',
      'delete': 'Supprimer',
      'user_deleted_success': 'Utilisateur supprimé avec succès',
      'error_deleting_user': 'Erreur lors de la suppression',
      'error_fetching_addresses': 'Erreur lors de la récupération des adresses',
      'super_admins': 'Super Admins',
      'user_management': 'Gestion des Utilisateurs',
      'drivers': 'Chauffeurs',
      'customers': 'Clients',
      'home': 'Accueil',
      'users': 'Utilisateurs',
      'no_user_management_found': 'Aucun gestionnaire utilisateur trouvé',
      'user_management_level': 'Gestion utilisateur (Niveau {level})',
      'no_drivers_found': 'Aucun chauffeur trouvé',
      'vehicle_code': 'Code Véhicule',
      'vehicle_registration_number': 'Numéro d\'immatriculation',
      'driver_level': 'Chauffeur (Niveau {level})',
      'no_customers_found': 'Aucun client trouvé',
      'document_type': 'Type de document',
      'document_number': 'Numéro de document',
      'customer_level': 'Client (Niveau {level})',
      'add_new_user_management': 'Ajouter un nouveau gestionnaire utilisateur',
      'personal': 'Personnel',
      'username_required': 'Le nom d\'utilisateur est requis',
      'first_name_required': 'Le prénom est requis',
      'last_name_required': 'Le nom de famille est requis',
      'username_min_length': 'Le nom d\'utilisateur doit contenir au moins 5 caractères',
      'invalid_email': 'Veuillez entrer une adresse email valide',
      'address_required': 'Au moins une adresse complète est requise',
      'user_created_success': 'Utilisateur créé avec succès',
      'no_addresses_found': 'Aucune adresse trouvée. Ajoutez au moins une adresse.',
      'add_another_address': 'Ajouter une autre adresse',
      'leave_password_empty': 'Laissez le mot de passe vide pour conserver le mot de passe actuel',
      'select_Office': 'Sélectionnez un bureau',
      'select_user_level': 'Sélectionnez le niveau utilisateur',
      'Country': 'Pays',



    },
    'ar': {
      // Existing Arabic keys (keeping all previous Arabic translations)
      'app_title': 'يان شيب للتوصيل',
      'driver_home': 'الصفحة الرئيسية للسائق',
      'orders': 'الطلبات',
      'new_order': 'طلب جديد',
      'order_details': 'تفاصيل الطلب',
      'order_status': 'حالة الطلب',
      'order_id': 'رقم الطلب',
      'customer_name': 'اسم العميل',
      'delivery_address': 'عنوان التوصيل',
      'phone_number': 'رقم الهاتف',
      'order_total': 'إجمالي الطلب',
      'accept_order': 'قبول الطلب',
      'decline_order': 'رفض الطلب',
      'mark_delivered': 'تحديد كمُسلّم',
      'mark_picked_up': 'تحديد كمُستلم',
      'pending': 'معلّق',
      'accepted': 'مقبول',
      'picked_up': 'مُستلم',
      'delivered': 'مُسلّم',
      'cancelled': 'ملغي',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'theme': 'المظهر',
      'light_mode': 'المظهر الفاتح',
      'dark_mode': 'المظهر الداكن',
      'system_mode': 'مظهر النظام',
      'english': 'English',
      'french': 'Français',
      'arabic': 'العربية',
      'notification_title': 'تحديث حالة الطلب',
      'order_accepted': 'تم قبول الطلب',
      'order_picked_up': 'تم استلام الطلب',
      'order_delivered': 'تم تسليم الطلب',
      'order_cancelled': 'تم إلغاء الطلب',
      'confirm_delivery': 'تأكيد التسليم',
      
      // Authentication & Welcome page keys in Arabic
      'welcome': 'مرحباً',
      'skip': 'تخطي',
      'login': 'تسجيل الدخول',
      'sign_in': 'تسجيل الدخول',
      'register': 'التسجيل',
      'sign_up': 'إنشاء حساب',
      'create_account': 'إنشاء حساب',
      'email_label': 'البريد الإلكتروني',
      'password_label': 'كلمة المرور',
      'confirm_password_label': 'تأكيد كلمة المرور',
      'first_name_label': 'الاسم الأول',
      'last_name_label': 'اسم العائلة',
      'username_label': 'اسم المستخدم',
      'phone_label': 'رقم الهاتف',
      'address_label': 'العنوان',
      'city_label': 'المدينة',
      'company_label': 'الشركة',
      'already_have_account': 'لديك حساب بالفعل؟',
      'dont_have_account': 'ليس لديك حساب؟',
      'please_enter_email_auth': 'يرجى إدخال بريدك الإلكتروني',
      'please_enter_password_auth': 'يرجى إدخال كلمة المرور',
      'please_enter_first_name_auth': 'يرجى إدخال الاسم الأول',
      'please_enter_last_name_auth': 'يرجى إدخال اسم العائلة',
      'please_enter_username_auth': 'يرجى إدخال اسم المستخدم',
      'please_enter_phone_auth': 'يرجى إدخال رقم الهاتف',
      'please_enter_address_auth': 'يرجى إدخال العنوان',
      'please_enter_city_auth': 'يرجى إدخال المدينة',
      'password_min_length_auth': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'passwords_not_match_auth': 'كلمات المرور غير متطابقة',
      'login_success': 'تم تسجيل الدخول بنجاح',
      'register_success': 'تم التسجيل بنجاح',
      'login_failed': 'فشل تسجيل الدخول',
      'register_failed': 'فشل التسجيل',
      'are_you_sure_delivery': 'هل أنت متأكد من أنك تريد تحديد هذا الطلب كمُسلّم؟',
      'yes': 'نعم',
      'no': 'لا',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'error': 'خطأ',
      'success': 'نجح',
      'loading': 'جاري التحميل...',
      'no_orders': 'لا توجد طلبات متاحة',
      'retry': 'إعادة المحاولة',
      'refresh': 'تحديث',
      
      // Dashboard keys
      'dashboard': 'لوحة التحكم',
      'driver_dashboard': 'لوحة تحكم السائق',
      'driver_id': 'هوية السائق',
      'total_orders': 'إجمالي الطلبات',
      'returned': 'مُرجعة',
      'performance_overview': 'نظرة عامة على الأداء',
      'success_rate': 'معدل النجاح',
      'earnings': 'الأرباح',
      'delivered_orders': 'الطلبات المُسلّمة',
      'delivered_amount': 'أرباح السائق (درهم)',
      'average_ticket': 'متوسط التذكرة',
      'pending_invoices': 'الفواتير المعلقة',
      
      // Order Details keys
      'order_information': 'معلومات الطلب',
      'order_no': 'رقم الطلب',
      'order_encoded': 'الطلب المُرمّز',
      'order_date': 'تاريخ الطلب',
      'customer_information': 'معلومات العميل',
      'receiver_name': 'اسم المُستلم',
      'person_receives': 'الشخص المُستلم',
      'phone': 'الهاتف',
      'address': 'العنوان',
      'city': 'المدينة',
      'payment_information': 'معلومات الدفع',
      'price': 'السعر',
      'price_after_fee': 'السعر بعد الرسوم',
      'to': 'إلى',
      'order_timeline': 'جدول زمني للطلب',
      'no_timeline_events': 'لا توجد أحداث زمنية',
      'notes': 'ملاحظات',
      'print_label': 'طباعة الملصق',
      'generate_shipping_label': 'إنشاء ملصق الشحن',
      
      // Order card and action keys
      'confirm_order_dialog_title': 'تأكيد الطلب',
      'confirm_order_dialog_message': 'سيؤدي هذا إلى تغيير الحالة إلى "مؤكد" وسيكون الطلب جاهزًا للاستلام.',
      'failed_to_confirm_order': 'فشل في تأكيد الطلب',
      'editable': 'قابل للتعديل',
      'na': 'غ/م',
      'modify_order_details': 'تعديل تفاصيل الطلب',
      'show_delivery_information': 'عرض معلومات التسليم',
      'mark_confirmed_ready': 'تحديد كمؤكد وجاهز',
      'delete_order_permanently': 'حذف الطلب نهائياً',
      'orders_picked_up_successfully': 'طلبات تم استلامها بنجاح',
      'failed_to_pickup_orders': 'فشل في استلام الطلبات',
      'order_confirmed_successfully': 'تم تأكيده بنجاح',
      'failed_to_cancel_order': 'فشل في إلغاء الطلب',
      'order': 'طلب',
      'error_picking_up_orders': 'خطأ في استلام الطلبات',
      'error_order_id_not_found': 'خطأ: لم يتم العثور على معرف الطلب',
      'error_cancelling_order': 'خطأ في إلغاء الطلب',
      'error_tracking_number_not_found': 'خطأ: لم يتم العثور على رقم التتبع',
      'error_confirming_order': 'خطأ في تأكيد الطلب',
      'error_loading_orders': 'خطأ في تحميل الطلبات',
      'recipient_name': 'اسم المستلم',
      'no_phone_number': 'لا يوجد رقم هاتف',
      'no_address': 'لا يوجد عنوان',
      'status_history': 'تاريخ الحالة',
      'delivery_status': 'حالة التسليم',
      'completed': 'مُكتمل',
      'proof_uploaded': 'تم رفع الدليل',
      'proof_file': 'ملف الدليل',
      'invoice_status': 'حالة الفاتورة',
      'generated': 'مُنتج',
      'not_generated': 'غير مُنتج',
      'status_note': 'ملاحظة الحالة',
      'status_cannot_change': 'لا يمكن تغيير هذه الحالة',
      'locked': 'مقفل',
      
      // HomePage specific keys
      'all': 'الكل',
      'unknown': 'مجهول',
      'print_bon_reception': 'طباعة بون الاستلام',
      'unknown_city': 'مدينة مجهولة',
      'status_created': 'مُنشأ',
      'status_confirmed': 'مؤكد',
      'status_in_transit': 'في الطريق',
      'status_picked_up': 'تم الاستلام',
      'status_out_for_delivery': 'في التوصيل',
      'status_attempted_delivery': 'محاولة توصيل',
      'status_delivered': 'تم التسليم',
      'status_returned': 'مُرتجع',
      'status_cancelled': 'ملغي',
      'status_rejected': 'مرفوض',
      
      // Profile keys
      'profile': 'الملف الشخصي',
      'personal_information': 'المعلومات الشخصية',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'email': 'البريد الإلكتروني',
      'username': 'اسم المستخدم',
      'rib': 'RIB',
      'cne': 'CNE',
      'ice': 'ICE',
      'last_login': 'آخر تسجيل دخول',
      'registration_date': 'تاريخ التسجيل',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'save_changes': 'حفظ التغييرات',
      'profile_updated_success': 'تم تحديث الملف الشخصي بنجاح',
      'please_enter_first_name': 'يرجى إدخال الاسم الأول',
      'please_enter_last_name': 'يرجى إدخال اسم العائلة',
      'please_enter_email': 'يرجى إدخال البريد الإلكتروني',
      'please_enter_valid_email': 'يرجى إدخال بريد إلكتروني صالح',
      'please_enter_username': 'يرجى إدخال اسم المستخدم',
      'please_enter_rib': 'يرجى إدخال RIB',
      'please_enter_cne': 'يرجى إدخال CNE',
      'please_enter_ice': 'يرجى إدخال ICE',
      'please_enter_phone': 'يرجى إدخال رقم الهاتف',
      'please_enter_address': 'يرجى إدخال العنوان',
      'please_enter_city': 'يرجى إدخال المدينة',
      'password_min_length': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'passwords_not_match': 'كلمات المرور غير متطابقة',
      'rating': 'التقييم',
      'connection_error': 'خطأ في الاتصال بالخادم',

      // Help & Support keys in Arabic
      'help_support': 'المساعدة والدعم',
      'emergency_support': 'الدعم الطارئ',
      'emergency_support_desc': 'لمشاكل التوصيل العاجلة أو الحالات الطارئة',
      'call_now': 'اتصل الآن',
      'whatsapp': 'واتساب',
      'could_not_open_whatsapp': 'لا يمكن فتح واتساب',
      'quick_actions': 'الإجراءات السريعة',
      'driver_status': 'حالة السائق',
      'driver_status_desc': 'تحديث التوفر، إعدادات الموقع',
      'delivery_history': 'تاريخ التوصيل',
      'delivery_history_desc': 'عرض التوصيلات السابقة والأرباح',
      'payment_info': 'معلومات الدفع',
      'payment_info_desc': 'التحقق من الأرباح وطرق الدفع',
      'opening_driver_status': 'فتح حالة السائق...',
      'opening_delivery_history': 'فتح تاريخ التوصيل...',
      'opening_payment_info': 'فتح معلومات الدفع...',
      'submit_support_request': 'إرسال طلب الدعم',
      'issue_type': 'نوع المشكلة',
      'technical_issue': 'مشكلة تقنية',
      'technical_issue_desc': 'تعطل التطبيق، مشاكل تسجيل الدخول، مشاكل GPS',
      'delivery_problem': 'مشكلة التوصيل',
      'delivery_problem_desc': 'لا يمكن العثور على العنوان، العميل غير متاح',
      'payment_issue': 'مشكلة الدفع',
      'payment_issue_desc': 'مدفوعات مفقودة، مبالغ غير صحيحة',
      'account_problem': 'مشكلة الحساب',
      'account_problem_desc': 'تحديثات الملف الشخصي، مشاكل التحقق',
      'other': 'أخرى',
      'other_desc': 'أسئلة عامة أو مخاوف أخرى',
      'describe_issue': 'وصف المشكلة',
      'describe_issue_placeholder': 'يرجى وصف مشكلتك بالتفصيل...',
      'please_describe_issue': 'يرجى وصف مشكلتك',
      'provide_more_details': 'يرجى تقديم المزيد من التفاصيل (10 أحرف على الأقل)',
      'submit_request': 'إرسال الطلب',
      'support_request_success': 'تم إرسال طلب الدعم بنجاح! سنعاود الاتصال بك قريباً.',
      'frequently_asked_questions': 'الأسئلة الشائعة',
      'faq_gps_title': 'GPS لا يعمل بشكل صحيح',
      'faq_gps_answer': 'حاول تمكين خدمات الموقع في إعدادات جهازك، أعد تشغيل التطبيق، أو تحقق من وجود أحدث إصدار من التطبيق مثبت.',
      'faq_payment_title': 'متى سأتلقى دفعتي؟',
      'faq_payment_answer': 'تتم معالجة المدفوعات أسبوعياً يوم الجمعة. يجب أن تتلقى أرباحك خلال 2-3 أيام عمل بعد المعالجة.',
      'faq_customer_title': 'العميل غير متاح',
      'faq_customer_answer': 'حاول الاتصال بالعميل أولاً. إذا لم يرد، انتظر 5 دقائق وحاول مرة أخرى. بعد 15 دقيقة، يمكنك وضع علامة "محاولة التسليم" وإرجاع الطرد.',

      // Invoice keys in Arabic - ADDED
      'invoices': 'الفواتير',
      'invoice_no': 'رقم الفاتورة',
      'date': 'التاريخ',
      'amount': 'المبلغ',
      'status': 'الحالة',
      'download': 'تحميل',
      'view': 'عرض',
      'coming_soon': 'قريباً!',
      'no_invoices_found': 'لم يتم العثور على فواتير',
      'paid': 'مدفوع',
      'history': 'التاريخ',
      
      // Welcome page specific keys in Arabic
      'app_name': 'يان شيب',
      'light_mode_tooltip': 'الوضع الفاتح',
      'dark_mode_tooltip': 'الوضع الداكن',
      'we_are_yanship': 'نحن يان شيب',
      'yanship_description': 'نحن هنا كشريك نحتاج إليك لتربح أكثر لأن ربحك هو ربحنا أيضاً، نحن نقدم خدمة التوصيل كما نقترح عليك باقة كاملة من الموردين إلى التوصيل دون قضاء وقت في ذلك للبقاء مركزاً على التوسع. لهذا يمكنك تسميتنا امتداد عملك.',
      'features': 'المميزات',
      'feature_description': 'اكتشف حلول التوصيل الشاملة',
      'fast_delivery': 'توصيل سريع',
      'secure_payment': 'دفع آمن',
      'real_time_tracking': 'تتبع فوري',
      'all_in_one_pack': 'نحن نقدم حزمة شاملة',
      'all_in_one_pack_desc': 'لا حاجة للتشتت بين الكثير من الخدمات، نحن نعطيك حزمة كاملة. فقط وسعها!',
      'fast_shipping': 'شحن سريع',
      'fast_shipping_desc': 'وقت التوصيل لدينا في جميع أنحاء المغرب بمتوسط وقت 24 ساعة. يلا!',
      'payment_24h': 'دفع 24 ساعة',
      'payment_24h_desc': 'نرسل المدفوعات يومياً لذلك لا يوجد تأخير في التدفق النقدي. رنين المال!',
      'pricing': 'الأسعار',
      'choose_plan': 'اختر خطتك',
      'silver': 'فضي',
      'gold': 'ذهبي',
      'platinum': 'بلاتيني',
      'month': '/شهر',
      'basic_features': 'مميزات التوصيل الأساسية',
      'advanced_features': 'مميزات متقدمة + دعم أولوية',
      'premium_features': 'جميع المميزات + دعم مميز',
      'contact_us': 'اتصل بنا',
      'get_in_touch': 'تواصل معنا',
      'contact_description': 'لديك أسئلة؟ نحب أن نسمع منك.',
      'name': 'الاسم',
      'name_hint': 'أدخل اسمك',
      'email_hint': 'أدخل بريدك الإلكتروني',
      'phone_hint': 'أدخل رقم هاتفك',
      'message': 'الرسالة',
      'message_hint': 'أدخل رسالتك',
      'send_message': 'إرسال الرسالة',
      'name_required': 'الاسم مطلوب',
      'email_required': 'البريد الإلكتروني مطلوب',
      'email_invalid': 'يرجى إدخال بريد إلكتروني صحيح',
      'phone_required': 'رقم الهاتف مطلوب',
      'message_required': 'الرسالة مطلوبة',
      'message_sent': 'تم إرسال الرسالة بنجاح!',
      'message_error': 'فشل في إرسال الرسالة. يرجى المحاولة مرة أخرى.',
      
      // VIP Plans and Pricing
      'vip_plans': 'خطط VIP',
      'choose_your_plan': 'اختر خطتك',
      'most_popular': 'الأكثر شعبية',
      'per_month': 'في الشهر',
      'get_started': 'ابدأ الآن',
      'select_plan': 'اختر الخطة',
      'free_trial': 'تجربة مجانية',
      'unlimited_deliveries': 'توصيلات غير محدودة',
      'priority_support_plan': 'دعم أولوي',
      'advanced_analytics': 'تحليلات متقدمة',
      'custom_branding': 'علامة تجارية مخصصة',
      'api_access': 'وصول API',
      
      // Home Page Elements
      'welcome_back': 'مرحباً بعودتك',
      'main_dashboard': 'لوحة التحكم',
      'quick_stats': 'إحصائيات سريعة',
      'total_deliveries': 'إجمالي التوصيلات',
      'completed_orders': 'الطلبات المكتملة',
      'pending_orders': 'الطلبات المعلقة',
      'earnings_today': 'أرباح اليوم',
      'recent_orders': 'الطلبات الحديثة',
      'view_all_orders': 'عرض جميع الطلبات',
      'no_recent_orders': 'لا توجد طلبات حديثة',
      'quick_actions_home': 'إجراءات سريعة',
      'new_delivery': 'توصيل جديد',
      'track_package': 'تتبع الطرد',
      'customer_support': 'دعم العملاء',
      'performance': 'الأداء',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'delivery_rate': 'معدل التوصيل',
      'customer_rating': 'تقييم العملاء',
      'on_time_delivery': 'التوصيل في الوقت المحدد',
      
      // Create Order Page
      'create_new_order': 'إنشاء طلب جديد',
      'customer_info': 'معلومات العميل',
      'customer_name_field': 'اسم العميل',
      'customer_phone': 'هاتف العميل',
      'customer_email': 'إيميل العميل',
      'delivery_info': 'معلومات التوصيل',
      'pickup_address': 'عنوان الاستلام',
      'delivery_address_field': 'عنوان التوصيل',
      'delivery_notes': 'ملاحظات التوصيل',
      'package_details': 'تفاصيل الطرد',
      'package_description': 'وصف الطرد',
      'package_weight': 'وزن الطرد',
      'package_dimensions': 'أبعاد الطرد',
      'fragile_item': 'عنصر قابل للكسر',
      'express_delivery': 'توصيل سريع',
      'delivery_fee': 'رسوم التوصيل',
      'total_amount': 'المبلغ الإجمالي',
      'payment_method': 'طريقة الدفع',
      'cash_on_delivery': 'الدفع عند التوصيل',
      'prepaid': 'مدفوع مسبقاً',
      'create_order_btn': 'إنشاء الطلب',
      'order_created_successfully': 'تم إنشاء الطلب بنجاح',
      'please_fill_required_fields': 'يرجى ملء جميع الحقول المطلوبة',
      
      // Create Order Page Additional Fields
      'create_order_page_title': 'إنشاء طلب جديد',
      'create_order_description': 'املأ جميع التفاصيل أدناه لإنشاء طلب التوصيل الخاص بك',
      'recipient_name_field': 'اسم المستلم',
      'recipient_name_hint': 'أدخل الاسم الكامل',
      'phone_number_field': 'رقم الهاتف',
      'phone_number_hint': '+966 50 123 4567',
      'city_field': 'المدينة',
      'city_hint': 'أدخل المدينة',
      'delivery_address_field_label': 'عنوان التوصيل',
      'delivery_address_hint': 'أدخل عنوان التوصيل الكامل',
      'order_price_field': 'سعر الطلب',
      'order_price_hint': '0.00 ر.س',
      'authorize_open_package': 'السماح بفتح الطرد',
      'authorize_open_package_description': 'ضع علامة في هذا المربع إذا كنت تأذن لشخص التوصيل بفتح الطرد لأغراض التحقق',
      
      // Form Validation Messages
      'name_required_error': 'الاسم مطلوب',
      'phone_required_error': 'رقم الهاتف مطلوب',
      'city_required_error': 'المدينة مطلوبة',
      'delivery_address_required_error': 'عنوان التوصيل مطلوب',
      'price_required_error': 'السعر مطلوب',
      'valid_price_required_error': 'أدخل سعر صحيح',
      
      // Error Messages
      'order_creation_failed': 'فشل في إنشاء الطلب',
      'try_again_button': 'حاول مرة أخرى',
      
      // Success Dialog Messages
      'order_success_description': 'تم إنشاء طلب التوصيل الخاص بك وسيتم معالجته قريباً. ستتلقى التحديثات عبر الإشعارات.',
      'create_another_order': 'إنشاء طلب آخر',
      'back_to_home': 'العودة للرئيسية',
      
      // Edit Order Page
      'edit_order': 'تعديل الطلب',
      'update_order': 'تحديث الطلب',
      'order_updated_successfully': 'تم تحديث الطلب بنجاح',
      'cancel_order': 'إلغاء الطلب',
      'order_cancelled_successfully': 'تم إلغاء الطلب بنجاح',
      'are_you_sure_cancel': 'هل أنت متأكد من إلغاء هذا الطلب؟',
      'order_info': 'معلومات الطلب',
      'tracking_number': 'رقم التتبع',
      'order_date_field': 'تاريخ الطلب',
      'estimated_delivery': 'التوصيل المقدر',
      'actual_delivery': 'التوصيل الفعلي',
      'delivery_proof': 'إثبات التوصيل',
      'upload_proof': 'رفع الإثبات',
      'add_note': 'إضافة ملاحظة',
      'order_notes': 'ملاحظات الطلب',
      
      // Edit Order Page Additional Fields
      'edit_order_title': 'تعديل الطلب',
      'edit_order_subtitle': 'إجراء تغييرات على تفاصيل الطلب',
      'customer_info_edit_section': 'معلومات العميل',
      'customer_info_edit_subtitle': 'تحديث تفاصيل المستلم',
      'delivery_info_edit_section': 'معلومات التوصيل',
      'delivery_info_edit_subtitle': 'تحديث عنوان التوصيل',
      'order_details_edit_section': 'تفاصيل الطلب',
      'order_details_edit_subtitle': 'تحديث الأسعار والملاحظات',
      'recipient_name_edit': 'اسم المستلم',
      'recipient_name_edit_hint': 'أدخل اسم المستلم',
      'phone_number_edit': 'رقم الهاتف',
      'phone_number_edit_hint': '+966 50 123 4567',
      'city_edit': 'المدينة',
      'city_edit_hint': 'أدخل اسم المدينة',
      'delivery_address_edit': 'عنوان التوصيل',
      'delivery_address_edit_hint': 'أدخل العنوان الكامل',
      'order_price_edit': 'سعر الطلب',
      'order_price_edit_hint': '0.00 ر.س',
      'special_notes': 'ملاحظات خاصة (اختياري)',
      'special_notes_hint': 'تعليمات خاصة...',
      'save_changes_tooltip': 'حفظ التغييرات',
      'cancel_edit': 'إلغاء',
      'update_order_button': 'تحديث الطلب',
      'order_update_success': 'تم تحديث الطلب بنجاح!',
      'order_update_success_desc': 'تم حفظ وتحديث التغييرات الخاصة بك.',
      'back_to_orders': 'العودة للطلبات',
      
      // Edit Order Validation Messages
      'name_required_edit': 'الاسم مطلوب',
      'phone_required_edit': 'رقم الهاتف مطلوب',
      'city_required_edit': 'المدينة مطلوبة',
      'address_required_edit': 'العنوان مطلوب',
      'price_required_edit': 'السعر مطلوب',
      
      // History Page
      'order_history': 'تاريخ الطلبات',
      'delivery_history_page': 'تاريخ التوصيلات',
      'filter_by': 'تصفية بواسطة',
      'all_orders': 'جميع الطلبات',
      'completed_status': 'مكتمل',
      'in_progress': 'قيد التنفيذ',
      'search_orders': 'البحث في الطلبات',
      'date_range': 'نطاق التاريخ',
      'from_date': 'من تاريخ',
      'to_date': 'إلى تاريخ',
      'apply_filter': 'تطبيق المرشح',
      'clear_filter': 'مسح المرشح',
      'export_data': 'تصدير البيانات',
      'total_earnings': 'إجمالي الأرباح',
      'average_rating': 'متوسط التقييم',
      'total_distance': 'إجمالي المسافة',
      'sort_by': 'ترتيب بواسطة',
      'date_newest': 'التاريخ (الأحدث)',
      'date_oldest': 'التاريخ (الأقدم)',
      'amount_highest': 'المبلغ (الأعلى)',
      'amount_lowest': 'المبلغ (الأقل)',
      
      // Profile Page Elements
      'my_profile': 'ملفي الشخصي',
      'personal_info': 'المعلومات الشخصية',
      'edit_profile': 'تعديل الملف الشخصي',
      'save_changes_btn': 'حفظ التغييرات',
      'account_settings': 'إعدادات الحساب',
      'change_password': 'تغيير كلمة المرور',
      'current_password': 'كلمة المرور الحالية',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
      'notification_settings': 'إعدادات الإشعارات',
      'push_notifications': 'إشعارات الدفع',
      'email_notifications': 'إشعارات الإيميل',
      'sms_notifications': 'إشعارات الرسائل النصية',
      'order_updates': 'تحديثات الطلبات',
      'promotional_offers': 'العروض الترويجية',
      'privacy_settings': 'إعدادات الخصوصية',
      'share_location': 'مشاركة الموقع',
      'profile_visibility': 'ظهور الملف الشخصي',
      'data_usage': 'استخدام البيانات',
      'logout': 'تسجيل الخروج',
      'delete_account': 'حذف الحساب',
      'about_app': 'حول التطبيق',
      'app_version': 'إصدار التطبيق',
      'terms_conditions': 'الشروط والأحكام',
      'privacy_policy': 'سياسة الخصوصية',
      'help_support_menu': 'المساعدة والدعم',
      'rate_app': 'تقييم التطبيق',
      'profile_updated_successfully': 'تم تحديث الملف الشخصي بنجاح',
      'password_changed_successfully': 'تم تغيير كلمة المرور بنجاح',
      'are_you_sure_logout': 'هل أنت متأكد من تسجيل الخروج؟',
      'are_you_sure_delete_account': 'هل أنت متأكد من حذف حسابك؟',
      
      // Login Page - Register Link
      'dont_have_account_login': 'ليس لديك حساب؟',
      'register_here': 'سجل هنا',
      'forgot_password': 'نسيت كلمة المرور؟',
      'remember_me': 'تذكرني',
      
      // Contact Form Elements
      'subject': 'الموضوع',
      'subject_hint': 'أدخل الموضوع',
      'your_message': 'رسالتك',
      'send_now': 'إرسال الآن',
      'contact_info': 'معلومات الاتصال',
      'our_address': 'عنواننا',
      'call_us': 'اتصل بنا',
      'email_us': 'راسلنا',
      'business_hours': 'ساعات العمل',
      'monday_friday': 'الاثنين - الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'closed': 'مغلق',
      
      // Additional Profile Elements - Arabic
      'ice_number': 'رقم ICE',
      'cne_number': 'رقم CNE',
      'update_avatar': 'تحديث الصورة الشخصية',
      'choose_method': 'اختر الطريقة',
      'take_photo': 'التقاط صورة',
      'choose_from_gallery': 'اختيار من المعرض',
      'change_password_btn': 'تغيير',
      'account_section': 'الحساب',
      'support_section': 'الدعم',
      'help_and_support': 'المساعدة والدعم',
      'get_help_with_orders': 'احصل على المساعدة مع طلباتك',
      'about_section': 'حول',
      'app_version_info': 'إصدار التطبيق والمعلومات',
      'sign_out_account': 'تسجيل الخروج من الحساب',
      'update_personal_info': 'تحديث معلوماتك الشخصية',
      'update_account_password': 'تحديث كلمة مرور الحساب',
      'manage_payment_options': 'إدارة خيارات الدفع',
      'payment_methods': 'طرق الدفع',
      'receive_order_updates': 'تلقي تحديثات الطلب',
      'switch_to_dark_theme': 'التبديل إلى المظهر الداكن',
      'no_email': 'لا يوجد بريد إلكتروني',
      'user_fallback': 'مستخدم',
      
      // Validation Messages - Arabic
      'first_name_min_chars': 'يجب أن يحتوي الاسم الأول على حرفين على الأقل',
      'last_name_min_chars': 'يجب أن يحتوي اسم العائلة على حرفين على الأقل',
      'ice_min_chars': 'يجب أن يحتوي رقم ICE على 3 أحرف على الأقل',
      'rib_min_chars': 'يجب أن يحتوي RIB على 10 أحرف على الأقل',
      'cne_min_chars': 'يجب أن يحتوي رقم CNE على 8 أحرف على الأقل',
      'company_min_chars': 'يجب أن يحتوي اسم الشركة على حرفين على الأقل',
      'website_must_start_http': 'يجب أن يبدأ الموقع الإلكتروني بـ http:// أو https://',
      'website_url_invalid': 'يجب أن يكون رابط الموقع الإلكتروني صالحًا',
      'at_least_one_field': 'يجب ملء حقل واحد على الأقل',
      'enter_current_password': 'يرجى إدخال كلمة المرور الحالية',
      'enter_new_password': 'يرجى إدخال كلمة مرور جديدة',
      'passwords_dont_match': 'كلمات المرور غير متطابقة',
      'new_password_min_chars': 'يجب أن تحتوي كلمة المرور الجديدة على 6 أحرف على الأقل',
      'profile_update_success': 'تم تحديث الملف الشخصي بنجاح!',
      'profile_update_failed': 'فشل في تحديث الملف الشخصي',
      'password_change_success': 'تم تغيير كلمة المرور بنجاح!',
      'password_change_failed': 'فشل في تغيير كلمة المرور',
      'avatar_updated_success': 'تم تحديث الصورة الشخصية بنجاح!',
      'avatar_update_failed': 'فشل في تحديث الصورة الشخصية',
      'notifications_updated': 'تم تحديث تفضيلات الإشعارات',
      'dark_mode_enabled': '🌙 تم تفعيل المظهر الداكن!',
      'light_mode_enabled': '☀️ تم تفعيل المظهر الفاتح!',
      'language_changed_to': 'تم تغيير اللغة إلى',
      'opening_help_center': 'فتح مركز المساعدة...',
      'payment_methods_coming_soon': 'ميزة طرق الدفع ستتوفر قريبًا!',
      'failed_load_profile': 'فشل في تحميل الملف الشخصي',
      'view_action': 'عرض',
      
      // Additional order details translations
      'order_details_title': 'تفاصيل الطلب',
      'close_button': 'إغلاق',
      'tracking_info_section': 'معلومات التتبع',
      'customer_info_section': 'معلومات العميل',
      'order_summary_section': 'ملخص الطلب',
      'print_invoice_button': 'طباعة الفاتورة',
      'print_button': 'طباعة',
      'cancel_button': 'إلغاء',
      'generate_invoice_dialog': 'إنشاء وطباعة فاتورة للطلب',
      'generating_invoice_text': 'جاري إنشاء الفاتورة...',
      'invoice_success_prefix': 'فاتورة للطلب',
      'invoice_success_suffix': 'تم إرسالها إلى الطابعة',
      
      // Overview and Analytics translations
      'recent_activity': 'النشاط الأخير',
      'performance_analytics': 'تحليلات الأداء',
      'average_delivery_time': 'متوسط وقت التسليم',
      'customer_satisfaction': 'رضا العملاء',
      'total_revenue': 'إجمالي الإيرادات',
      'delivery_statistics': 'إحصائيات التسليم',
      'overview': 'نظرة عامة',
      'analytics': 'التحليلات',
      'tracking_id': 'رقم التتبع',
      'delivery_time': 'وقت التسليم',
      'recipient': 'المستلم',
      'to_prefix': 'إلى:',

      //elkadn3
      'searchDrivers': 'ابحث عن السائقين...',
      'searchCustomers': 'ابحث عن العملاء...',
      'searchAdmins': 'ابحث عن المسؤولين...',
      'sendEmail': 'إرسال بريد إلكتروني',
      'emailAddress': 'البريد الإلكتروني',
      'copyEmailMessage': 'يمكنك نسخ البريد الإلكتروني لاستخدامه في تطبيق البريد الإلكتروني المفضل لديك.',
      'copyEmail': 'نسخ البريد الإلكتروني',
      'emailCopied': 'تم نسخ البريد الإلكتروني',
      'contactMessages': 'رسائل التواصل',
      'openAnyway': 'افتح على أي حال',
      'number': 'رقم',
      'phoneAppWillOpen': 'سيتم فتح تطبيق الهاتف بهذا الرقم مسبقاً.',
      'sortAscending': 'ترتيب تصاعدي',
      'sortDescending': 'ترتيب تنازلي',
      'switchToLightMode': 'التبديل إلى الوضع الفاتح',
      'switchToDarkMode': 'التبديل إلى الوضع الداكن',
      'searchMessages': 'ابحث عن الرسائل...',
      'noMessagesFound': 'لا توجد رسائل',
      'messageDeletedSuccessfully': 'تم حذف الرسالة بنجاح',
      'deleteMessageConfirm': 'هل تريد حقًا حذف الرسالة من',
      'call': 'اتصال',
      'cannotMakePhoneCall': 'لا يمكن إجراء مكالمة هاتفية',
      'cannotOpenWhatsApp': 'لا يمكن فتح واتساب',
      'sortOldestFirst': 'ترتيب الأقدم أولاً',
      'sortNewestFirst': 'ترتيب الأحدث أولاً',
      'no_city_found' : 'لا توجد مدينة حاليا',
      'search_cities': 'إبحث عن مدينة ...',
      'description_optional': 'الوصف (اختياري)',
      'please_enter_city_name': 'الرجاء إدخال اسم المدينة',
      'city_name': 'اسم المدينة',
      'add_city': 'إضافة مدينة',
      'edit_city': 'تعديل المدينة',
      'updated': 'تم التحديث',
      'city_deleted_successfully': 'تم حذف المدينة بنجاح',
      'cannot_delete_city': 'لا يمكن حذف المدينة. يتم استخدامها في الطلبات.',
      'city_updated_successfully': 'تم تحديث المدينة بنجاح',
      'city_name_exists': 'اسم المدينة موجود بالفعل',
      'city_created_successfully': 'تم إنشاء المدينة بنجاح',
      'delete_city_confirm': 'تأكيد حذف المدينة',
      'cities_management': 'إدارة المدن',
      'edit_driver': 'تعديل السائق',
      'cities_page': 'صفحة المدن',
      'contacts_page': 'صفحة جهات الاتصال',
      'noStatusHistory': 'لا يوجد سجل للحالة متاح',
      'insufficientPermissions': 'صلاحيات غير كافية',
      'accessDenied': 'تم رفض الوصول',
      'please_select_city': 'الرجاء اختيار مدينة',
      'changeCity': 'تغيير المدينة',
      'commission': 'العمولة',
      'currentCity': 'المدينة الحالية',
      'print': 'طباعة',
      'label_printed_success': 'تمت طباعة الملصق بنجاح',
      'currentStatus' : 'الحالة الحالية',
      'select_new_status': 'اختر حالة جديدة',
      'assign_or_change_driver': 'تعيين أو تغيير سائق التوصيل',
      'updating_status': 'جارٍ تحديث الحالة...',
      'update_status': 'تحديث الحالة',
      'note_optional': 'ملاحظة (اختياري)',
      'select_status': 'اختر الحالة',
      'update_order_status': 'تحديث حالة الطلب',
      'selection_required': 'مطلوب اختيار',
      'please_select_driver': 'يرجى اختيار سائق',
      'ok': 'موافق',
      'driver_assigned_success': 'تم تعيين السائق بنجاح',
      'driver_assignment_failed': 'فشل في التعيين',
      'assign_driver': 'تعيين سائق',
      'no_driver_available': 'لا يوجد سائق متاح',
      'select_driver': 'اختر سائق',
      'assign': 'تعيين',
      'nonAssigned': 'غير محدد',
      'driver': 'السائق',
      'sender': 'المرسل',
      'customer_created_success': 'تم إنشاء الزبون بنجاح !',
      'driver_created_success': 'تم إنشاء السائق بنجاح !',
      'server_timeout': 'استغرق الخادم وقتًا طويلاً للرد !',
      'order_actions': 'إجراءات الطلب',
      'tracking_view_details': 'التتبع: عرض التفاصيل',
      'confirm_order': 'تأكيد الطلب',

      'no_orders_yet': 'لا توجد طلبات بعد. يرجى انتظار طلبات العملاء',
      'shipment_list': 'قائمة الشحنات',
      "user_updated_successfully": "تم تحديث المستخدم بنجاح!",
      "add_new_customer": "إضافة عميل جديد",
      "add_new_driver": "إضافة سائق جديد",
      "edit_user_management": "تعديل إدارة المستخدم",
      "edit_customer": "تعديل العميل",
      "next": "التالي",
      "previous": "السابق",
      "submit": "إرسال",
      "user_status": "حالة المستخدم",
      "newsletter_subscription": "الاشتراك في النشرة الإخبارية",
      "internal_notes": "ملاحظات داخلية",
      'super_admins': 'المشرفين الرئيسيين',
      'user_management': 'إدارة المستخدمين',
      'drivers': 'السائقين',
      'customers': 'العملاء',
      'home': 'الرئيسية',
      'users': 'المستخدمين',
      'no_super_admins_found': 'لم يتم العثور على مشرفين رئيسيين',
      'gender': 'الجنس',
      'office': 'المكتب',
      'user_level': 'مستوى المستخدم',
      'created': 'تم الإنشاء',
      'not_specified': 'غير محدد',
      'active': 'نشط',
      'inactive': 'غير نشط',
      'close': 'إغلاق',
      'addresses_of': 'عناوين',
      'no_address_found': 'لم يتم العثور على عناوين',
      'confirm_deletion': 'تأكيد الحذف',
      'delete_user_confirm': 'هل أنت متأكد أنك تريد حذف',
      'delete': 'حذف',
      'user_deleted_success': 'تم حذف المستخدم بنجاح',
      'error_deleting_user': 'خطأ أثناء الحذف',
      'error_fetching_addresses': 'خطأ في جلب العناوين',
      'no_user_management_found': 'لم يتم العثور على إدارة مستخدمين',
      'user_management_level': 'إدارة المستخدمين (المستوى {level})',
      'no_drivers_found': 'لم يتم العثور على سائقين',
      'vehicle_code': 'رمز المركبة',
      'vehicle_registration_number': 'رقم تسجيل المركبة',
      'driver_level': 'سائق (المستوى {level})',
      'no_customers_found': 'لم يتم العثور على عملاء',
      'document_type': 'نوع المستند',
      'document_number': 'رقم المستند',
      'customer_level': 'عميل (المستوى {level})',
      'add_new_user_management': 'إضافة مدير مستخدمين جديد',
      'personal': 'شخصي',
      'username_required': 'اسم المستخدم مطلوب',
      'first_name_required': 'الاسم الأول مطلوب',
      'last_name_required': 'الاسم الأخير مطلوب',
      'username_min_length': 'يجب أن يحتوي اسم المستخدم على 5 أحرف على الأقل',
      'invalid_email': 'يرجى إدخال عنوان بريد إلكتروني صالح',
      'address_required': 'مطلوب عنوان واحد كامل على الأقل',
      'user_created_success': 'تم إنشاء المستخدم بنجاح',
      'no_addresses_found': 'لم يتم العثور على عناوين. أضف عنوانًا واحدًا على الأقل.',
      'add_another_address': 'إضافة عنوان آخر',
      'leave_password_empty': 'اترك كلمة المرور فارغة للاحتفاظ بكلمة المرور الحالية',
      'select_Office': 'اختر المكتب',
      'select_user_level': 'اختر مستوى المستخدم',
      'Country"=': 'البلد',
      "Zip_Code": "الرمز البريدي",



    },
  };

  // Existing getters
  String get appTitle => _localizedValues[locale.languageCode]!['app_title']!;
  String get driverHome => _localizedValues[locale.languageCode]!['driver_home']!;
  String get orders => _localizedValues[locale.languageCode]!['orders']!;
  String get newOrder => _localizedValues[locale.languageCode]!['new_order']!;
  String get orderDetails => _localizedValues[locale.languageCode]!['order_details']!;
  String get orderStatus => _localizedValues[locale.languageCode]!['order_status']!;
  String get orderId => _localizedValues[locale.languageCode]!['order_id']!;
  String get customerName => _localizedValues[locale.languageCode]!['customer_name']!;
  String get deliveryAddress => _localizedValues[locale.languageCode]!['delivery_address']!;
  String get phoneNumber => _localizedValues[locale.languageCode]!['phone_number']!;
  String get orderTotal => _localizedValues[locale.languageCode]!['order_total']!;
  String get acceptOrder => _localizedValues[locale.languageCode]!['accept_order']!;
  String get declineOrder => _localizedValues[locale.languageCode]!['decline_order']!;
  String get markDelivered => _localizedValues[locale.languageCode]!['mark_delivered']!;
  String get markPickedUp => _localizedValues[locale.languageCode]!['mark_picked_up']!;
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get accepted => _localizedValues[locale.languageCode]!['accepted']!;
  String get pickedUp => _localizedValues[locale.languageCode]!['picked_up']!;
  String get delivered => _localizedValues[locale.languageCode]!['delivered']!;
  String get cancelled => _localizedValues[locale.languageCode]!['cancelled']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get lightMode => _localizedValues[locale.languageCode]!['light_mode']!;
  String get darkMode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get systemMode => _localizedValues[locale.languageCode]!['system_mode']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get french => _localizedValues[locale.languageCode]!['french']!;
  String get arabic => _localizedValues[locale.languageCode]!['arabic']!;
  String get notificationTitle => _localizedValues[locale.languageCode]!['notification_title']!;
  String get orderAccepted => _localizedValues[locale.languageCode]!['order_accepted']!;
  String get orderPickedUp => _localizedValues[locale.languageCode]!['order_picked_up']!;
  String get orderDelivered => _localizedValues[locale.languageCode]!['order_delivered']!;
  String get orderCancelled => _localizedValues[locale.languageCode]!['order_cancelled']!;
  String get confirmDelivery => _localizedValues[locale.languageCode]!['confirm_delivery']!;
  String get areYouSureDelivery => _localizedValues[locale.languageCode]!['are_you_sure_delivery']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get noOrders => _localizedValues[locale.languageCode]!['no_orders']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get refresh => _localizedValues[locale.languageCode]!['refresh']!;
  String get changeStatus => _localizedValues[locale.languageCode]!['changeStatus']!;
  String get generateInvoice => _localizedValues[locale.languageCode]!['generateInvoice']!;

  // Dashboard getters
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get driverDashboard => _localizedValues[locale.languageCode]!['driver_dashboard']!;
  String get driverId => _localizedValues[locale.languageCode]!['driver_id']!;
  String get totalOrders => _localizedValues[locale.languageCode]!['total_orders']!;
  String get returned => _localizedValues[locale.languageCode]!['returned']!;
  String get performanceOverview => _localizedValues[locale.languageCode]!['performance_overview']!;
  String get successRate => _localizedValues[locale.languageCode]!['success_rate']!;
  String get earnings => _localizedValues[locale.languageCode]!['earnings']!;
  String get deliveredOrders => _localizedValues[locale.languageCode]!['delivered_orders']!;
  String get deliveredAmount => _localizedValues[locale.languageCode]!['delivered_amount']!;
  String get averageTicket => _localizedValues[locale.languageCode]!['average_ticket']!;
  String get pendingInvoices => _localizedValues[locale.languageCode]!['pending_invoices']!;

  // Order Details getters
  String get orderInformation => _localizedValues[locale.languageCode]!['order_information']!;
  String get orderNo => _localizedValues[locale.languageCode]!['order_no']!;
  String get orderEncoded => _localizedValues[locale.languageCode]!['order_encoded']!;
  String get orderDate => _localizedValues[locale.languageCode]!['order_date']!;
  String get customerInformation => _localizedValues[locale.languageCode]!['customer_information']!;
  String get receiverName => _localizedValues[locale.languageCode]!['receiver_name']!;
  String get personReceives => _localizedValues[locale.languageCode]!['person_receives']!;
  String get phone => _localizedValues[locale.languageCode]!['phone']!;
  String get address => _localizedValues[locale.languageCode]!['address']!;
  String get city => _localizedValues[locale.languageCode]!['city']!;
  String get paymentInformation => _localizedValues[locale.languageCode]!['payment_information']!;
  String get price => _localizedValues[locale.languageCode]!['price']!;
  String get priceAfterFee => _localizedValues[locale.languageCode]!['price_after_fee']!;
  String get to => _localizedValues[locale.languageCode]!['to']!;
  String get orderTimeline => _localizedValues[locale.languageCode]!['order_timeline']!;
  String get noTimelineEvents => _localizedValues[locale.languageCode]!['no_timeline_events']!;
  String get notes => _localizedValues[locale.languageCode]!['notes']!;
  String get printLabel => _localizedValues[locale.languageCode]!['print_label']!;
  String get generateShippingLabel => _localizedValues[locale.languageCode]!['generate_shipping_label']!;
  String get confirmOrderDialogTitle => _localizedValues[locale.languageCode]!['confirm_order_dialog_title']!;
  String get confirmOrderDialogMessage => _localizedValues[locale.languageCode]!['confirm_order_dialog_message']!;
  String get failedToConfirmOrder => _localizedValues[locale.languageCode]!['failed_to_confirm_order']!;
  String get editable => _localizedValues[locale.languageCode]!['editable']!;
  String get na => _localizedValues[locale.languageCode]!['na']!;
  String get modifyOrderDetails => _localizedValues[locale.languageCode]!['modify_order_details']!;
  String get showDeliveryInformation => _localizedValues[locale.languageCode]!['show_delivery_information']!;
  String get markConfirmedReady => _localizedValues[locale.languageCode]!['mark_confirmed_ready']!;
  String get deleteOrderPermanently => _localizedValues[locale.languageCode]!['delete_order_permanently']!;
  String get ordersPickedUpSuccessfully => _localizedValues[locale.languageCode]!['orders_picked_up_successfully']!;
  String get failedToPickupOrders => _localizedValues[locale.languageCode]!['failed_to_pickup_orders']!;
  String get orderConfirmedSuccessfully => _localizedValues[locale.languageCode]!['order_confirmed_successfully']!;
  String get failedToCancelOrder => _localizedValues[locale.languageCode]!['failed_to_cancel_order']!;
  String get order => _localizedValues[locale.languageCode]!['order']!;
  String get errorPickingUpOrders => _localizedValues[locale.languageCode]!['error_picking_up_orders']!;
  String get errorOrderIdNotFound => _localizedValues[locale.languageCode]!['error_order_id_not_found']!;
  String get errorCancellingOrder => _localizedValues[locale.languageCode]!['error_cancelling_order']!;
  String get errorTrackingNumberNotFound => _localizedValues[locale.languageCode]!['error_tracking_number_not_found']!;
  String get errorConfirmingOrder => _localizedValues[locale.languageCode]!['error_confirming_order']!;
  String get errorLoadingOrders => _localizedValues[locale.languageCode]!['error_loading_orders']!;
  String get recipientName => _localizedValues[locale.languageCode]!['recipient_name']!;
  String get noPhoneNumber => _localizedValues[locale.languageCode]!['no_phone_number']!;
  String get noAddress => _localizedValues[locale.languageCode]!['no_address']!;
  String get statusHistory => _localizedValues[locale.languageCode]!['status_history']!;
  String get deliveryStatus => _localizedValues[locale.languageCode]!['delivery_status']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get proofUploaded => _localizedValues[locale.languageCode]!['proof_uploaded']!;
  String get proofFile => _localizedValues[locale.languageCode]!['proof_file']!;
  String get invoiceStatus => _localizedValues[locale.languageCode]!['invoice_status']!;
  String get generated => _localizedValues[locale.languageCode]!['generated']!;
  String get notGenerated => _localizedValues[locale.languageCode]!['not_generated']!;
  String get statusNote => _localizedValues[locale.languageCode]!['status_note']!;
  String get statusCannotChange => _localizedValues[locale.languageCode]!['status_cannot_change']!;
  String get locked => _localizedValues[locale.languageCode]!['locked']!;

  // HomePage getters
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get unknown => _localizedValues[locale.languageCode]!['unknown']!;
  String get printBonReception => _localizedValues[locale.languageCode]!['print_bon_reception']!;
  String get unknownCity => _localizedValues[locale.languageCode]!['unknown_city']!;
  String get statusCreated => _localizedValues[locale.languageCode]!['status_created']!;
  String get statusConfirmed => _localizedValues[locale.languageCode]!['status_confirmed']!;
  String get statusInTransit => _localizedValues[locale.languageCode]!['status_in_transit']!;
  String get statusPickedUp => _localizedValues[locale.languageCode]!['status_picked_up']!;
  String get statusOutForDelivery => _localizedValues[locale.languageCode]!['status_out_for_delivery']!;
  String get statusAttemptedDelivery => _localizedValues[locale.languageCode]!['status_attempted_delivery']!;
  String get statusDelivered => _localizedValues[locale.languageCode]!['status_delivered']!;
  String get statusReturned => _localizedValues[locale.languageCode]!['status_returned']!;
  String get statusCancelled => _localizedValues[locale.languageCode]!['status_cancelled']!;
  String get statusRejected => _localizedValues[locale.languageCode]!['status_rejected']!;

  // Profile getters
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get personalInformation => _localizedValues[locale.languageCode]!['personal_information']!;
  String get firstName => _localizedValues[locale.languageCode]!['first_name']!;
  String get lastName => _localizedValues[locale.languageCode]!['last_name']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get username => _localizedValues[locale.languageCode]!['username']!;
  String get rib => _localizedValues[locale.languageCode]!['rib']!;
  String get cne => _localizedValues[locale.languageCode]!['cne']!;
  String get ice => _localizedValues[locale.languageCode]!['ice']!;
  String get lastLogin => _localizedValues[locale.languageCode]!['last_login']!;
  String get registrationDate => _localizedValues[locale.languageCode]!['registration_date']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get confirmPassword => _localizedValues[locale.languageCode]!['confirm_password']!;
  String get saveChanges => _localizedValues[locale.languageCode]!['save_changes']!;
  String get profileUpdatedSuccess => _localizedValues[locale.languageCode]!['profile_updated_success']!;
  String get pleaseEnterFirstName => _localizedValues[locale.languageCode]!['please_enter_first_name']!;
  String get pleaseEnterLastName => _localizedValues[locale.languageCode]!['please_enter_last_name']!;
  String get pleaseEnterEmail => _localizedValues[locale.languageCode]!['please_enter_email']!;
  String get pleaseEnterValidEmail => _localizedValues[locale.languageCode]!['please_enter_valid_email']!;
  String get pleaseEnterUsername => _localizedValues[locale.languageCode]!['please_enter_username']!;
  String get pleaseEnterRib => _localizedValues[locale.languageCode]!['please_enter_rib']!;
  String get pleaseEnterCne => _localizedValues[locale.languageCode]!['please_enter_cne']!;
  String get pleaseEnterIce => _localizedValues[locale.languageCode]!['please_enter_ice']!;
  String get pleaseEnterPhone => _localizedValues[locale.languageCode]!['please_enter_phone']!;
  String get pleaseEnterAddress => _localizedValues[locale.languageCode]!['please_enter_address']!;
  String get pleaseEnterCity => _localizedValues[locale.languageCode]!['please_enter_city']!;
  String get passwordMinLength => _localizedValues[locale.languageCode]!['password_min_length']!;
  String get passwordsNotMatch => _localizedValues[locale.languageCode]!['passwords_not_match']!;
  String get rating => _localizedValues[locale.languageCode]!['rating']!;
  String get connectionError => _localizedValues[locale.languageCode]!['connection_error']!;

  // Help & Support getters
  String get helpSupport => _localizedValues[locale.languageCode]!['help_support']!;
  String get emergencySupport => _localizedValues[locale.languageCode]!['emergency_support']!;
  String get emergencySupportDesc => _localizedValues[locale.languageCode]!['emergency_support_desc']!;
  String get callNow => _localizedValues[locale.languageCode]!['call_now']!;
  String get whatsapp => _localizedValues[locale.languageCode]!['whatsapp']!;
  String get couldNotOpenWhatsapp => _localizedValues[locale.languageCode]!['could_not_open_whatsapp']!;
  String get quickActions => _localizedValues[locale.languageCode]!['quick_actions']!;
  String get driverStatus => _localizedValues[locale.languageCode]!['driver_status']!;
  String get driverStatusDesc => _localizedValues[locale.languageCode]!['driver_status_desc']!;
  String get deliveryHistory => _localizedValues[locale.languageCode]!['delivery_history']!;
  String get deliveryHistoryDesc => _localizedValues[locale.languageCode]!['delivery_history_desc']!;
  String get paymentInfo => _localizedValues[locale.languageCode]!['payment_info']!;
  String get paymentInfoDesc => _localizedValues[locale.languageCode]!['payment_info_desc']!;
  String get openingDriverStatus => _localizedValues[locale.languageCode]!['opening_driver_status']!;
  String get openingDeliveryHistory => _localizedValues[locale.languageCode]!['opening_delivery_history']!;
  String get openingPaymentInfo => _localizedValues[locale.languageCode]!['opening_payment_info']!;
  String get submitSupportRequest => _localizedValues[locale.languageCode]!['submit_support_request']!;
  String get issueType => _localizedValues[locale.languageCode]!['issue_type']!;
  String get technicalIssue => _localizedValues[locale.languageCode]!['technical_issue']!;
  String get technicalIssueDesc => _localizedValues[locale.languageCode]!['technical_issue_desc']!;
  String get deliveryProblem => _localizedValues[locale.languageCode]!['delivery_problem']!;
  String get deliveryProblemDesc => _localizedValues[locale.languageCode]!['delivery_problem_desc']!;
  String get paymentIssue => _localizedValues[locale.languageCode]!['payment_issue']!;
  String get paymentIssueDesc => _localizedValues[locale.languageCode]!['payment_issue_desc']!;
  String get accountProblem => _localizedValues[locale.languageCode]!['account_problem']!;
  String get accountProblemDesc => _localizedValues[locale.languageCode]!['account_problem_desc']!;
  String get other => _localizedValues[locale.languageCode]!['other']!;
  String get otherDesc => _localizedValues[locale.languageCode]!['other_desc']!;
  String get describeIssue => _localizedValues[locale.languageCode]!['describe_issue']!;
  String get describeIssuePlaceholder => _localizedValues[locale.languageCode]!['describe_issue_placeholder']!;
  String get pleaseDescribeIssue => _localizedValues[locale.languageCode]!['please_describe_issue']!;
  String get provideMoreDetails => _localizedValues[locale.languageCode]!['provide_more_details']!;
  String get submitRequest => _localizedValues[locale.languageCode]!['submit_request']!;
  String get supportRequestSuccess => _localizedValues[locale.languageCode]!['support_request_success']!;
  String get frequentlyAskedQuestions => _localizedValues[locale.languageCode]!['frequently_asked_questions']!;
  String get faqGpsTitle => _localizedValues[locale.languageCode]!['faq_gps_title']!;
  String get faqGpsAnswer => _localizedValues[locale.languageCode]!['faq_gps_answer']!;
  String get faqPaymentTitle => _localizedValues[locale.languageCode]!['faq_payment_title']!;
  String get faqPaymentAnswer => _localizedValues[locale.languageCode]!['faq_payment_answer']!;
  String get faqCustomerTitle => _localizedValues[locale.languageCode]!['faq_customer_title']!;
  String get faqCustomerAnswer => _localizedValues[locale.languageCode]!['faq_customer_answer']!;

  // Authentication & Welcome page getters
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get skip => _localizedValues[locale.languageCode]!['skip']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get signIn => _localizedValues[locale.languageCode]!['sign_in']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get signUp => _localizedValues[locale.languageCode]!['sign_up']!;
  String get createAccount => _localizedValues[locale.languageCode]!['create_account']!;
  String get emailLabel => _localizedValues[locale.languageCode]!['email_label']!;
  String get passwordLabel => _localizedValues[locale.languageCode]!['password_label']!;
  String get confirmPasswordLabel => _localizedValues[locale.languageCode]!['confirm_password_label']!;
  String get firstNameLabel => _localizedValues[locale.languageCode]!['first_name_label']!;
  String get lastNameLabel => _localizedValues[locale.languageCode]!['last_name_label']!;
  String get usernameLabel => _localizedValues[locale.languageCode]!['username_label']!;
  String get phoneLabel => _localizedValues[locale.languageCode]!['phone_label']!;
  String get addressLabel => _localizedValues[locale.languageCode]!['address_label']!;
  String get cityLabel => _localizedValues[locale.languageCode]!['city_label']!;
  String get companyLabel => _localizedValues[locale.languageCode]!['company_label']!;
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]!['already_have_account']!;
  String get dontHaveAccount => _localizedValues[locale.languageCode]!['dont_have_account']!;
  String get pleaseEnterEmailAuth => _localizedValues[locale.languageCode]!['please_enter_email_auth']!;
  String get pleaseEnterPasswordAuth => _localizedValues[locale.languageCode]!['please_enter_password_auth']!;
  String get pleaseEnterFirstNameAuth => _localizedValues[locale.languageCode]!['please_enter_first_name_auth']!;
  String get pleaseEnterLastNameAuth => _localizedValues[locale.languageCode]!['please_enter_last_name_auth']!;
  String get pleaseEnterUsernameAuth => _localizedValues[locale.languageCode]!['please_enter_username_auth']!;
  String get pleaseEnterPhoneAuth => _localizedValues[locale.languageCode]!['please_enter_phone_auth']!;
  String get pleaseEnterAddressAuth => _localizedValues[locale.languageCode]!['please_enter_address_auth']!;
  String get pleaseEnterCityAuth => _localizedValues[locale.languageCode]!['please_enter_city_auth']!;
  String get passwordMinLengthAuth => _localizedValues[locale.languageCode]!['password_min_length_auth']!;
  String get passwordsNotMatchAuth => _localizedValues[locale.languageCode]!['passwords_not_match_auth']!;
  String get loginSuccess => _localizedValues[locale.languageCode]!['login_success']!;
  String get registerSuccess => _localizedValues[locale.languageCode]!['register_success']!;
  String get loginFailed => _localizedValues[locale.languageCode]!['login_failed']!;
  String get registerFailed => _localizedValues[locale.languageCode]!['register_failed']!;

  // Invoice getters - ADDED
  String get invoices => _localizedValues[locale.languageCode]!['invoices']!;
  String get invoiceNo => _localizedValues[locale.languageCode]!['invoice_no']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get amount => _localizedValues[locale.languageCode]!['amount']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String get download => _localizedValues[locale.languageCode]!['download']!;
  String get view => _localizedValues[locale.languageCode]!['view']!;
  String get comingSoon => _localizedValues[locale.languageCode]!['coming_soon']!;
  String get noInvoicesFound => _localizedValues[locale.languageCode]!['no_invoices_found']!;
  String get paid => _localizedValues[locale.languageCode]!['paid']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  
  // Welcome page getters
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get lightModeTooltip => _localizedValues[locale.languageCode]!['light_mode_tooltip']!;
  String get darkModeTooltip => _localizedValues[locale.languageCode]!['dark_mode_tooltip']!;
  String get weAreYanship => _localizedValues[locale.languageCode]!['we_are_yanship']!;
  String get yanshipDescription => _localizedValues[locale.languageCode]!['yanship_description']!;
  String get features => _localizedValues[locale.languageCode]!['features']!;
  String get featureDescription => _localizedValues[locale.languageCode]!['feature_description']!;
  String get fastDelivery => _localizedValues[locale.languageCode]!['fast_delivery']!;
  String get securePayment => _localizedValues[locale.languageCode]!['secure_payment']!;
  String get realTimeTracking => _localizedValues[locale.languageCode]!['real_time_tracking']!;
  String get allInOnePack => _localizedValues[locale.languageCode]!['all_in_one_pack']!;
  String get allInOnePackDesc => _localizedValues[locale.languageCode]!['all_in_one_pack_desc']!;
  String get fastShipping => _localizedValues[locale.languageCode]!['fast_shipping']!;
  String get fastShippingDesc => _localizedValues[locale.languageCode]!['fast_shipping_desc']!;
  String get payment24h => _localizedValues[locale.languageCode]!['payment_24h']!;
  String get payment24hDesc => _localizedValues[locale.languageCode]!['payment_24h_desc']!;
  String get pricing => _localizedValues[locale.languageCode]!['pricing']!;
  String get choosePlan => _localizedValues[locale.languageCode]!['choose_plan']!;
  String get silver => _localizedValues[locale.languageCode]!['silver']!;
  String get gold => _localizedValues[locale.languageCode]!['gold']!;
  String get platinum => _localizedValues[locale.languageCode]!['platinum']!;
  String get month => _localizedValues[locale.languageCode]!['month']!;
  String get basicFeatures => _localizedValues[locale.languageCode]!['basic_features']!;
  String get advancedFeatures => _localizedValues[locale.languageCode]!['advanced_features']!;
  String get premiumFeatures => _localizedValues[locale.languageCode]!['premium_features']!;
  String get contactUs => _localizedValues[locale.languageCode]!['contact_us']!;
  String get getInTouch => _localizedValues[locale.languageCode]!['get_in_touch']!;
  String get contactDescription => _localizedValues[locale.languageCode]!['contact_description']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get nameHint => _localizedValues[locale.languageCode]!['name_hint']!;
  String get emailHint => _localizedValues[locale.languageCode]!['email_hint']!;
  String get phoneHint => _localizedValues[locale.languageCode]!['phone_hint']!;
  String get message => _localizedValues[locale.languageCode]!['message']!;
  String get messageHint => _localizedValues[locale.languageCode]!['message_hint']!;
  String get sendMessage => _localizedValues[locale.languageCode]!['send_message']!;
  String get nameRequired => _localizedValues[locale.languageCode]!['name_required']!;
  String get emailRequired => _localizedValues[locale.languageCode]!['email_required']!;
  String get emailInvalid => _localizedValues[locale.languageCode]!['email_invalid']!;
  String get phoneRequired => _localizedValues[locale.languageCode]!['phone_required']!;
  String get messageRequired => _localizedValues[locale.languageCode]!['message_required']!;
  String get messageSent => _localizedValues[locale.languageCode]!['message_sent']!;
  String get messageError => _localizedValues[locale.languageCode]!['message_error']!;
  
  // VIP Plans and Pricing
  String get vipPlans => _localizedValues[locale.languageCode]!['vip_plans']!;
  String get chooseYourPlan => _localizedValues[locale.languageCode]!['choose_your_plan']!;
  String get mostPopular => _localizedValues[locale.languageCode]!['most_popular']!;
  String get perMonth => _localizedValues[locale.languageCode]!['per_month']!;
  String get getStarted => _localizedValues[locale.languageCode]!['get_started']!;
  String get selectPlan => _localizedValues[locale.languageCode]!['select_plan']!;
  String get freeTrial => _localizedValues[locale.languageCode]!['free_trial']!;
  String get unlimitedDeliveries => _localizedValues[locale.languageCode]!['unlimited_deliveries']!;
  String get prioritySupportPlan => _localizedValues[locale.languageCode]!['priority_support_plan']!;
  String get advancedAnalytics => _localizedValues[locale.languageCode]!['advanced_analytics']!;
  String get customBranding => _localizedValues[locale.languageCode]!['custom_branding']!;
  String get apiAccess => _localizedValues[locale.languageCode]!['api_access']!;
  
  // Home Page Elements
  String get welcomeBack => _localizedValues[locale.languageCode]!['welcome_back']!;
  String get mainDashboard => _localizedValues[locale.languageCode]!['main_dashboard']!;
  String get quickStats => _localizedValues[locale.languageCode]!['quick_stats']!;
  String get totalDeliveries => _localizedValues[locale.languageCode]!['total_deliveries']!;
  String get completedOrders => _localizedValues[locale.languageCode]!['completed_orders']!;
  String get pendingOrders => _localizedValues[locale.languageCode]!['pending_orders']!;
  String get earningsToday => _localizedValues[locale.languageCode]!['earnings_today']!;
  String get recentOrders => _localizedValues[locale.languageCode]!['recent_orders']!;
  String get viewAllOrders => _localizedValues[locale.languageCode]!['view_all_orders']!;
  String get noRecentOrders => _localizedValues[locale.languageCode]!['no_recent_orders']!;
  String get quickActionsHome => _localizedValues[locale.languageCode]!['quick_actions_home']!;
  String get newDelivery => _localizedValues[locale.languageCode]!['new_delivery']!;
  String get trackPackage => _localizedValues[locale.languageCode]!['track_package']!;
  String get customerSupport => _localizedValues[locale.languageCode]!['customer_support']!;
  String get performance => _localizedValues[locale.languageCode]!['performance']!;
  String get thisWeek => _localizedValues[locale.languageCode]!['this_week']!;
  String get thisMonth => _localizedValues[locale.languageCode]!['this_month']!;
  String get deliveryRate => _localizedValues[locale.languageCode]!['delivery_rate']!;
  String get customerRating => _localizedValues[locale.languageCode]!['customer_rating']!;
  String get onTimeDelivery => _localizedValues[locale.languageCode]!['on_time_delivery']!;
  
  // Create Order Page
  String get createNewOrder => _localizedValues[locale.languageCode]!['create_new_order']!;
  String get customerInfo => _localizedValues[locale.languageCode]!['customer_info']!;
  String get customerNameField => _localizedValues[locale.languageCode]!['customer_name_field']!;
  String get customerPhone => _localizedValues[locale.languageCode]!['customer_phone']!;
  String get customerEmail => _localizedValues[locale.languageCode]!['customer_email']!;
  String get deliveryInfo => _localizedValues[locale.languageCode]!['delivery_info']!;
  String get pickupAddress => _localizedValues[locale.languageCode]!['pickup_address']!;
  String get deliveryAddressField => _localizedValues[locale.languageCode]!['delivery_address_field']!;
  String get deliveryNotes => _localizedValues[locale.languageCode]!['delivery_notes']!;
  String get packageDetails => _localizedValues[locale.languageCode]!['package_details']!;
  String get packageDescription => _localizedValues[locale.languageCode]!['package_description']!;
  String get packageWeight => _localizedValues[locale.languageCode]!['package_weight']!;
  String get packageDimensions => _localizedValues[locale.languageCode]!['package_dimensions']!;
  String get fragileItem => _localizedValues[locale.languageCode]!['fragile_item']!;
  String get expressDelivery => _localizedValues[locale.languageCode]!['express_delivery']!;
  String get deliveryFee => _localizedValues[locale.languageCode]!['delivery_fee']!;
  String get totalAmount => _localizedValues[locale.languageCode]!['total_amount']!;
  String get paymentMethod => _localizedValues[locale.languageCode]!['payment_method']!;
  String get cashOnDelivery => _localizedValues[locale.languageCode]!['cash_on_delivery']!;
  String get prepaid => _localizedValues[locale.languageCode]!['prepaid']!;
  String get createOrderBtn => _localizedValues[locale.languageCode]!['create_order_btn']!;
  String get orderCreatedSuccessfully => _localizedValues[locale.languageCode]!['order_created_successfully']!;
  String get pleaseFillRequiredFields => _localizedValues[locale.languageCode]!['please_fill_required_fields']!;
  
  // Create Order Page Additional Fields
  String get createOrderPageTitle => _localizedValues[locale.languageCode]!['create_order_page_title']!;
  String get createOrderDescription => _localizedValues[locale.languageCode]!['create_order_description']!;
  String get recipientNameField => _localizedValues[locale.languageCode]!['recipient_name_field']!;
  String get recipientNameHint => _localizedValues[locale.languageCode]!['recipient_name_hint']!;
  String get phoneNumberField => _localizedValues[locale.languageCode]!['phone_number_field']!;
  String get phoneNumberHint => _localizedValues[locale.languageCode]!['phone_number_hint']!;
  String get cityField => _localizedValues[locale.languageCode]!['city_field']!;
  String get cityHint => _localizedValues[locale.languageCode]!['city_hint']!;
  String get deliveryAddressFieldLabel => _localizedValues[locale.languageCode]!['delivery_address_field_label']!;
  String get deliveryAddressHint => _localizedValues[locale.languageCode]!['delivery_address_hint']!;
  String get orderPriceField => _localizedValues[locale.languageCode]!['order_price_field']!;
  String get orderPriceHint => _localizedValues[locale.languageCode]!['order_price_hint']!;
  String get authorizeOpenPackage => _localizedValues[locale.languageCode]!['authorize_open_package']!;
  String get authorizeOpenPackageDescription => _localizedValues[locale.languageCode]!['authorize_open_package_description']!;
  
  // Form Validation Messages
  String get nameRequiredError => _localizedValues[locale.languageCode]!['name_required_error']!;
  String get phoneRequiredError => _localizedValues[locale.languageCode]!['phone_required_error']!;
  String get cityRequiredError => _localizedValues[locale.languageCode]!['city_required_error']!;
  String get deliveryAddressRequiredError => _localizedValues[locale.languageCode]!['delivery_address_required_error']!;
  String get priceRequiredError => _localizedValues[locale.languageCode]!['price_required_error']!;
  String get validPriceRequiredError => _localizedValues[locale.languageCode]!['valid_price_required_error']!;
  
  // Error Messages
  String get orderCreationFailed => _localizedValues[locale.languageCode]!['order_creation_failed']!;
  String get tryAgainButton => _localizedValues[locale.languageCode]!['try_again_button']!;
  
  // Success Dialog Messages
  String get orderSuccessDescription => _localizedValues[locale.languageCode]!['order_success_description']!;
  String get createAnotherOrder => _localizedValues[locale.languageCode]!['create_another_order']!;
  String get backToHome => _localizedValues[locale.languageCode]!['back_to_home']!;
  
  // Edit Order Page
  String get editOrder => _localizedValues[locale.languageCode]!['edit_order']!;
  String get updateOrder => _localizedValues[locale.languageCode]!['update_order']!;
  String get orderUpdatedSuccessfully => _localizedValues[locale.languageCode]!['order_updated_successfully']!;
  String get cancelOrder => _localizedValues[locale.languageCode]!['cancel_order']!;
  String get orderCancelledSuccessfully => _localizedValues[locale.languageCode]!['order_cancelled_successfully']!;
  String get areYouSureCancel => _localizedValues[locale.languageCode]!['are_you_sure_cancel']!;
  String get orderInfo => _localizedValues[locale.languageCode]!['order_info']!;
  String get trackingNumber => _localizedValues[locale.languageCode]!['tracking_number']!;
  String get orderDateField => _localizedValues[locale.languageCode]!['order_date_field']!;
  String get estimatedDelivery => _localizedValues[locale.languageCode]!['estimated_delivery']!;
  String get actualDelivery => _localizedValues[locale.languageCode]!['actual_delivery']!;
  String get deliveryProof => _localizedValues[locale.languageCode]!['delivery_proof']!;
  String get uploadProof => _localizedValues[locale.languageCode]!['upload_proof']!;
  String get addNote => _localizedValues[locale.languageCode]!['add_note']!;
  String get orderNotes => _localizedValues[locale.languageCode]!['order_notes']!;
  
  // Edit Order Page Additional Fields
  String get editOrderTitle => _localizedValues[locale.languageCode]!['edit_order_title']!;
  String get editOrderSubtitle => _localizedValues[locale.languageCode]!['edit_order_subtitle']!;
  String get customerInfoEditSection => _localizedValues[locale.languageCode]!['customer_info_edit_section']!;
  String get customerInfoEditSubtitle => _localizedValues[locale.languageCode]!['customer_info_edit_subtitle']!;
  String get deliveryInfoEditSection => _localizedValues[locale.languageCode]!['delivery_info_edit_section']!;
  String get deliveryInfoEditSubtitle => _localizedValues[locale.languageCode]!['delivery_info_edit_subtitle']!;
  String get orderDetailsEditSection => _localizedValues[locale.languageCode]!['order_details_edit_section']!;
  String get orderDetailsEditSubtitle => _localizedValues[locale.languageCode]!['order_details_edit_subtitle']!;
  String get recipientNameEdit => _localizedValues[locale.languageCode]!['recipient_name_edit']!;
  String get recipientNameEditHint => _localizedValues[locale.languageCode]!['recipient_name_edit_hint']!;
  String get phoneNumberEdit => _localizedValues[locale.languageCode]!['phone_number_edit']!;
  String get phoneNumberEditHint => _localizedValues[locale.languageCode]!['phone_number_edit_hint']!;
  String get cityEdit => _localizedValues[locale.languageCode]!['city_edit']!;
  String get cityEditHint => _localizedValues[locale.languageCode]!['city_edit_hint']!;
  String get deliveryAddressEdit => _localizedValues[locale.languageCode]!['delivery_address_edit']!;
  String get deliveryAddressEditHint => _localizedValues[locale.languageCode]!['delivery_address_edit_hint']!;
  String get orderPriceEdit => _localizedValues[locale.languageCode]!['order_price_edit']!;
  String get orderPriceEditHint => _localizedValues[locale.languageCode]!['order_price_edit_hint']!;
  String get specialNotes => _localizedValues[locale.languageCode]!['special_notes']!;
  String get specialNotesHint => _localizedValues[locale.languageCode]!['special_notes_hint']!;
  String get saveChangesTooltip => _localizedValues[locale.languageCode]!['save_changes_tooltip']!;
  String get cancelEdit => _localizedValues[locale.languageCode]!['cancel_edit']!;
  String get updateOrderButton => _localizedValues[locale.languageCode]!['update_order_button']!;
  String get orderUpdateSuccess => _localizedValues[locale.languageCode]!['order_update_success']!;
  String get orderUpdateSuccessDesc => _localizedValues[locale.languageCode]!['order_update_success_desc']!;
  String get backToOrders => _localizedValues[locale.languageCode]!['back_to_orders']!;
  
  // Edit Order Validation Messages
  String get nameRequiredEdit => _localizedValues[locale.languageCode]!['name_required_edit']!;
  String get phoneRequiredEdit => _localizedValues[locale.languageCode]!['phone_required_edit']!;
  String get cityRequiredEdit => _localizedValues[locale.languageCode]!['city_required_edit']!;
  String get addressRequiredEdit => _localizedValues[locale.languageCode]!['address_required_edit']!;
  String get priceRequiredEdit => _localizedValues[locale.languageCode]!['price_required_edit']!;
  
  // History Page
  String get orderHistory => _localizedValues[locale.languageCode]!['order_history']!;
  String get deliveryHistoryPage => _localizedValues[locale.languageCode]!['delivery_history_page']!;
  String get filterBy => _localizedValues[locale.languageCode]!['filter_by']!;
  String get allOrders => _localizedValues[locale.languageCode]!['all_orders']!;
  String get completedStatus => _localizedValues[locale.languageCode]!['completed_status']!;
  String get inProgress => _localizedValues[locale.languageCode]!['in_progress']!;
  String get searchOrders => _localizedValues[locale.languageCode]!['search_orders']!;
  String get dateRange => _localizedValues[locale.languageCode]!['date_range']!;
  String get fromDate => _localizedValues[locale.languageCode]!['from_date']!;
  String get toDate => _localizedValues[locale.languageCode]!['to_date']!;
  String get applyFilter => _localizedValues[locale.languageCode]!['apply_filter']!;
  String get clearFilter => _localizedValues[locale.languageCode]!['clear_filter']!;
  String get exportData => _localizedValues[locale.languageCode]!['export_data']!;
  String get totalEarnings => _localizedValues[locale.languageCode]!['total_earnings']!;
  String get averageRating => _localizedValues[locale.languageCode]!['average_rating']!;
  String get totalDistance => _localizedValues[locale.languageCode]!['total_distance']!;
  String get sortBy => _localizedValues[locale.languageCode]!['sort_by']!;
  String get dateNewest => _localizedValues[locale.languageCode]!['date_newest']!;
  String get dateOldest => _localizedValues[locale.languageCode]!['date_oldest']!;
  String get amountHighest => _localizedValues[locale.languageCode]!['amount_highest']!;
  String get amountLowest => _localizedValues[locale.languageCode]!['amount_lowest']!;
  
  // Profile Page Elements
  String get myProfile => _localizedValues[locale.languageCode]!['my_profile']!;
  String get personalInfo => _localizedValues[locale.languageCode]!['personal_info']!;
  String get editProfile => _localizedValues[locale.languageCode]!['edit_profile']!;
  String get saveChangesBtn => _localizedValues[locale.languageCode]!['save_changes_btn']!;
  String get accountSettings => _localizedValues[locale.languageCode]!['account_settings']!;
  String get changePassword => _localizedValues[locale.languageCode]!['change_password']!;
  String get currentPassword => _localizedValues[locale.languageCode]!['current_password']!;
  String get newPassword => _localizedValues[locale.languageCode]!['new_password']!;
  String get confirmNewPassword => _localizedValues[locale.languageCode]!['confirm_new_password']!;
  String get notificationSettings => _localizedValues[locale.languageCode]!['notification_settings']!;
  String get pushNotifications => _localizedValues[locale.languageCode]!['push_notifications']!;
  String get emailNotifications => _localizedValues[locale.languageCode]!['email_notifications']!;
  String get smsNotifications => _localizedValues[locale.languageCode]!['sms_notifications']!;
  String get orderUpdates => _localizedValues[locale.languageCode]!['order_updates']!;
  String get promotionalOffers => _localizedValues[locale.languageCode]!['promotional_offers']!;
  String get privacySettings => _localizedValues[locale.languageCode]!['privacy_settings']!;
  String get shareLocation => _localizedValues[locale.languageCode]!['share_location']!;
  String get profileVisibility => _localizedValues[locale.languageCode]!['profile_visibility']!;
  String get dataUsage => _localizedValues[locale.languageCode]!['data_usage']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get deleteAccount => _localizedValues[locale.languageCode]!['delete_account']!;
  String get aboutApp => _localizedValues[locale.languageCode]!['about_app']!;
  String get appVersion => _localizedValues[locale.languageCode]!['app_version']!;
  String get termsConditions => _localizedValues[locale.languageCode]!['terms_conditions']!;
  String get privacyPolicy => _localizedValues[locale.languageCode]!['privacy_policy']!;
  String get helpSupportMenu => _localizedValues[locale.languageCode]!['help_support_menu']!;
  String get rateApp => _localizedValues[locale.languageCode]!['rate_app']!;
  String get profileUpdatedSuccessfully => _localizedValues[locale.languageCode]!['profile_updated_successfully']!;
  String get passwordChangedSuccessfully => _localizedValues[locale.languageCode]!['password_changed_successfully']!;
  String get areYouSureLogout => _localizedValues[locale.languageCode]!['are_you_sure_logout']!;
  String get areYouSureDeleteAccount => _localizedValues[locale.languageCode]!['are_you_sure_delete_account']!;
  
  // Login Page - Register Link
  String get dontHaveAccountLogin => _localizedValues[locale.languageCode]!['dont_have_account_login']!;
  String get registerHere => _localizedValues[locale.languageCode]!['register_here']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgot_password']!;
  String get rememberMe => _localizedValues[locale.languageCode]!['remember_me']!;
  
  // Contact Form Elements
  String get subject => _localizedValues[locale.languageCode]!['subject']!;
  String get subjectHint => _localizedValues[locale.languageCode]!['subject_hint']!;
  String get yourMessage => _localizedValues[locale.languageCode]!['your_message']!;
  String get sendNow => _localizedValues[locale.languageCode]!['send_now']!;
  String get contactInfo => _localizedValues[locale.languageCode]!['contact_info']!;
  String get ourAddress => _localizedValues[locale.languageCode]!['our_address']!;
  String get callUs => _localizedValues[locale.languageCode]!['call_us']!;
  String get emailUs => _localizedValues[locale.languageCode]!['email_us']!;
  String get businessHours => _localizedValues[locale.languageCode]!['business_hours']!;
  String get mondayFriday => _localizedValues[locale.languageCode]!['monday_friday']!;
  String get saturday => _localizedValues[locale.languageCode]!['saturday']!;
  String get sunday => _localizedValues[locale.languageCode]!['sunday']!;
  String get closed => _localizedValues[locale.languageCode]!['closed']!;
  
  // Additional Profile Getters
  String get iceNumber => _localizedValues[locale.languageCode]!['ice_number']!;
  String get cneNumber => _localizedValues[locale.languageCode]!['cne_number']!;
  String get updateAvatar => _localizedValues[locale.languageCode]!['update_avatar']!;
  String get chooseMethod => _localizedValues[locale.languageCode]!['choose_method']!;
  String get takePhoto => _localizedValues[locale.languageCode]!['take_photo']!;
  String get chooseFromGallery => _localizedValues[locale.languageCode]!['choose_from_gallery']!;
  String get changePasswordBtn => _localizedValues[locale.languageCode]!['change_password_btn']!;
  String get accountSection => _localizedValues[locale.languageCode]!['account_section']!;
  String get supportSection => _localizedValues[locale.languageCode]!['support_section']!;
  String get helpAndSupport => _localizedValues[locale.languageCode]!['help_and_support']!;
  String get getHelpWithOrders => _localizedValues[locale.languageCode]!['get_help_with_orders']!;
  String get aboutSection => _localizedValues[locale.languageCode]!['about_section']!;
  String get appVersionInfo => _localizedValues[locale.languageCode]!['app_version_info']!;
  String get signOutAccount => _localizedValues[locale.languageCode]!['sign_out_account']!;
  String get updatePersonalInfo => _localizedValues[locale.languageCode]!['update_personal_info']!;
  String get updateAccountPassword => _localizedValues[locale.languageCode]!['update_account_password']!;
  String get managePaymentOptions => _localizedValues[locale.languageCode]!['manage_payment_options']!;
  String get paymentMethods => _localizedValues[locale.languageCode]!['payment_methods']!;
  String get receiveOrderUpdates => _localizedValues[locale.languageCode]!['receive_order_updates']!;
  String get switchToDarkTheme => _localizedValues[locale.languageCode]!['switch_to_dark_theme']!;
  String get noEmail => _localizedValues[locale.languageCode]!['no_email']!;
  String get userFallback => _localizedValues[locale.languageCode]!['user_fallback']!;
  
  // Validation Message Getters
  String get firstNameMinChars => _localizedValues[locale.languageCode]!['first_name_min_chars']!;
  String get lastNameMinChars => _localizedValues[locale.languageCode]!['last_name_min_chars']!;
  String get iceMinChars => _localizedValues[locale.languageCode]!['ice_min_chars']!;
  String get ribMinChars => _localizedValues[locale.languageCode]!['rib_min_chars']!;
  String get cneMinChars => _localizedValues[locale.languageCode]!['cne_min_chars']!;
  String get companyMinChars => _localizedValues[locale.languageCode]!['company_min_chars']!;
  String get websiteMustStartHttp => _localizedValues[locale.languageCode]!['website_must_start_http']!;
  String get websiteUrlInvalid => _localizedValues[locale.languageCode]!['website_url_invalid']!;
  String get atLeastOneField => _localizedValues[locale.languageCode]!['at_least_one_field']!;
  String get enterCurrentPassword => _localizedValues[locale.languageCode]!['enter_current_password']!;
  String get enterNewPassword => _localizedValues[locale.languageCode]!['enter_new_password']!;
  String get passwordsDontMatch => _localizedValues[locale.languageCode]!['passwords_dont_match']!;
  String get newPasswordMinChars => _localizedValues[locale.languageCode]!['new_password_min_chars']!;
  String get profileUpdateSuccess => _localizedValues[locale.languageCode]!['profile_update_success']!;
  String get profileUpdateFailed => _localizedValues[locale.languageCode]!['profile_update_failed']!;
  String get passwordChangeSuccess => _localizedValues[locale.languageCode]!['password_change_success']!;
  String get passwordChangeFailed => _localizedValues[locale.languageCode]!['password_change_failed']!;
  String get avatarUpdatedSuccess => _localizedValues[locale.languageCode]!['avatar_updated_success']!;
  String get avatarUpdateFailed => _localizedValues[locale.languageCode]!['avatar_update_failed']!;
  String get notificationsUpdated => _localizedValues[locale.languageCode]!['notifications_updated']!;
  String get darkModeEnabled => _localizedValues[locale.languageCode]!['dark_mode_enabled']!;
  String get lightModeEnabled => _localizedValues[locale.languageCode]!['light_mode_enabled']!;
  String get languageChangedTo => _localizedValues[locale.languageCode]!['language_changed_to']!;
  String get openingHelpCenter => _localizedValues[locale.languageCode]!['opening_help_center']!;
  String get paymentMethodsComingSoon => _localizedValues[locale.languageCode]!['payment_methods_coming_soon']!;
  String get failedLoadProfile => _localizedValues[locale.languageCode]!['failed_load_profile']!;
  String get viewAction => _localizedValues[locale.languageCode]!['view_action']!;
  
  // Additional order details getters
  String get orderDetailsTitle => _localizedValues[locale.languageCode]!['order_details_title']!;
  String get closeButton => _localizedValues[locale.languageCode]!['close_button']!;
  String get trackingInfoSection => _localizedValues[locale.languageCode]!['tracking_info_section']!;
  String get customerInfoSection => _localizedValues[locale.languageCode]!['customer_info_section']!;
  String get orderSummarySection => _localizedValues[locale.languageCode]!['order_summary_section']!;
  String get printInvoiceButton => _localizedValues[locale.languageCode]!['print_invoice_button']!;
  String get printButton => _localizedValues[locale.languageCode]!['print_button']!;
  String get cancelButton => _localizedValues[locale.languageCode]!['cancel_button']!;
  String get generateInvoiceDialog => _localizedValues[locale.languageCode]!['generate_invoice_dialog']!;
  String get generatingInvoiceText => _localizedValues[locale.languageCode]!['generating_invoice_text']!;
  String get invoiceSuccessPrefix => _localizedValues[locale.languageCode]!['invoice_success_prefix']!;
  String get invoiceSuccessSuffix => _localizedValues[locale.languageCode]!['invoice_success_suffix']!;
  
  // Additional getters for existing keys
  String get trackingId => _localizedValues[locale.languageCode]!['tracking_id']!;
  String get deliveryTime => _localizedValues[locale.languageCode]!['delivery_time']!;
  String get recipient => _localizedValues[locale.languageCode]!['recipient']!;
  
  // Overview and Analytics getters
  String get recentActivity => _localizedValues[locale.languageCode]!['recent_activity']!;
  String get performanceAnalytics => _localizedValues[locale.languageCode]!['performance_analytics']!;
  String get averageDeliveryTime => _localizedValues[locale.languageCode]!['average_delivery_time']!;
  String get customerSatisfaction => _localizedValues[locale.languageCode]!['customer_satisfaction']!;
  String get totalRevenue => _localizedValues[locale.languageCode]!['total_revenue']!;
  String get deliveryStatistics => _localizedValues[locale.languageCode]!['delivery_statistics']!;
  String get overview => _localizedValues[locale.languageCode]!['overview']!;
  String get analytics => _localizedValues[locale.languageCode]!['analytics']!;
  String get toPrefix => _localizedValues[locale.languageCode]!['to_prefix']!;


  // elkadn4
  String get searchDrivers {
    return _localizedValues[locale.languageCode]!['searchDrivers']!;
  }

  String get searchCustomers {
    return _localizedValues[locale.languageCode]!['searchCustomers']!;
  }

  String get searchAdmins {
    return _localizedValues[locale.languageCode]!['searchAdmins']!;
  }

  String get sendEmail {
    return _localizedValues[locale.languageCode]!['sendEmail']!;
  }

  String get emailAddress {
    return _localizedValues[locale.languageCode]!['emailAddress']!;
  }

  String get copyEmailMessage {
    return _localizedValues[locale.languageCode]!['copyEmailMessage']!;
  }

  String get copyEmail {
    return _localizedValues[locale.languageCode]!['copyEmail']!;
  }

  String get emailCopied {
    return _localizedValues[locale.languageCode]!['emailCopied']!;
  }

  String get openAnyway {
    return _localizedValues[locale.languageCode]!['openAnyway']!;
  }

  String get number {
    return _localizedValues[locale.languageCode]!['number']!;
  }

  String get phoneAppWillOpen {
    return _localizedValues[locale.languageCode]!['phoneAppWillOpen']!;
  }

  String get contactMessages {
    return _localizedValues[locale.languageCode]!['contactMessages']!;
  }

  String get searchMessages {
    return _localizedValues[locale.languageCode]!['searchMessages']!;
  }

  String get noMessagesFound {
    return _localizedValues[locale.languageCode]!['noMessagesFound']!;
  }

  String get messageDeletedSuccessfully {
    return _localizedValues[locale.languageCode]!['messageDeletedSuccessfully']!;
  }

  String get deleteMessageConfirm {
    return _localizedValues[locale.languageCode]!['deleteMessageConfirm']!;
  }

  String get call {
    return _localizedValues[locale.languageCode]!['call']!;
  }



  String get cannotMakePhoneCall {
    return _localizedValues[locale.languageCode]!['cannotMakePhoneCall']!;
  }

  String get cannotOpenWhatsApp {
    return _localizedValues[locale.languageCode]!['cannotOpenWhatsApp']!;
  }

  String get sortOldestFirst {
    return _localizedValues[locale.languageCode]!['sortOldestFirst']!;
  }

  String get sortNewestFirst {
    return _localizedValues[locale.languageCode]!['sortNewestFirst']!;
  }

  String get sortAscending {
    return _localizedValues[locale.languageCode]!['sortAscending']!;
  }

  String get sortDescending {
    return _localizedValues[locale.languageCode]!['sortDescending']!;
  }

  String get switchToLightMode {
    return _localizedValues[locale.languageCode]!['switchToLightMode']!;
  }

  String get switchToDarkMode {
    return _localizedValues[locale.languageCode]!['switchToDarkMode']!;
  }

  String get noCitiesFound {
    return _localizedValues[locale.languageCode]!['no_city_found']!;
  }

  String get searchCities {
    return _localizedValues[locale.languageCode]!['search_cities']!;
  }
  String get descriptionOptional {
    return _localizedValues[locale.languageCode]!['description_optional']!;
  }

  String get pleaseEnterCityName {
    return _localizedValues[locale.languageCode]!['please_enter_city_name']!;
  }

  String get cityName {
    return _localizedValues[locale.languageCode]!['city_name']!;
  }

  String get addCity {
    return _localizedValues[locale.languageCode]!['add_city']!;
  }

  String get editCity {
    return _localizedValues[locale.languageCode]!['edit_city']!;
  }
  String get updated {
    return _localizedValues[locale.languageCode]!['updated']!;
  }

  String get cityDeletedSuccessfully {
    return _localizedValues[locale.languageCode]!['city_deleted_successfully']!;
  }

  String get cannotDeleteCity {
    return _localizedValues[locale.languageCode]!['cannot_delete_city']!;
  }

  String get cityUpdatedSuccessfully {
    return _localizedValues[locale.languageCode]!['city_updated_successfully']!;
  }

  String get cityNameExists {
    return _localizedValues[locale.languageCode]!['city_name_exists']!;
  }

  String get cityCreatedSuccessfully {
    return _localizedValues[locale.languageCode]!['city_created_successfully']!;
  }
  String get deleteCityConfirm {
    return _localizedValues[locale.languageCode]!['delete_city_confirm']!;
  }

  String get citiesManagement {
    return _localizedValues[locale.languageCode]!['cities_management']!;
  }

  String get editDriver {
    return _localizedValues[locale.languageCode]!['edit_driver']!;
  }

  String get citiesPage {
    return _localizedValues[locale.languageCode]!['cities_page']!;
  }

  String get contactsPage {
    return _localizedValues[locale.languageCode]!['contacts_page']!;
  }

  String get insufficientPermissions {
    return _localizedValues[locale.languageCode]!['insufficientPermissions']!;
  }

  String get accessDenied {
    return _localizedValues[locale.languageCode]!['accessDenied']!;
  }

  String get noStatusHistory {
  return _localizedValues[locale.languageCode]!['noStatusHistory']!;
  }

  String get changeCity {
    return _localizedValues[locale.languageCode]!['changeCity']!;
  }

  String get pleaseSelectCity {
    return _localizedValues[locale.languageCode]!['please_select_city']!;
  }

  String get commission {
    return _localizedValues[locale.languageCode]!['commission']!;
  }

  String get currentCity {
    return _localizedValues[locale.languageCode]!['currentCity']!;
  }
  String get labelPrintedSuccess {
    return _localizedValues[locale.languageCode]!['label_printed_success']!;
  }
  String get print {
    return _localizedValues[locale.languageCode]!['print']!;
  }
  String get currentStatus {
    return _localizedValues[locale.languageCode]!['currentStatus']!;
  }
  String get selectNewStatus {
    return _localizedValues[locale.languageCode]!['select_new_status']!;
  }
  String get assignOrChangeDriver {
    return _localizedValues[locale.languageCode]!['assign_or_change_driver']!;
  }

  String get updatingStatus {
    return _localizedValues[locale.languageCode]!['updating_status']!;
  }
  String get updateStatus => _localizedValues[locale.languageCode]?['update_status'] ?? 'Update Status';


  String get noteOptional {
    return _localizedValues[locale.languageCode]!['note_optional']!;
  }

  String get selectStatus {
    return _localizedValues[locale.languageCode]!['select_status']!;
  }

  String get updateOrderStatus {
    return _localizedValues[locale.languageCode]!['update_order_status']!;
  }
  String get selectionRequired => _localizedValues[locale.languageCode]!['selection_required']!;
  String get pleaseSelectDriver => _localizedValues[locale.languageCode]!['please_select_driver']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get driverAssignedSuccess => _localizedValues[locale.languageCode]!['driver_assigned_success']!;
  String get driverAssignmentFailed => _localizedValues[locale.languageCode]!['driver_assignment_failed']!;
  String get assignDriver => _localizedValues[locale.languageCode]!['assign_driver']!;
  String get noDriverAvailable => _localizedValues[locale.languageCode]!['no_driver_available']!;
  String get selectDriver => _localizedValues[locale.languageCode]!['select_driver']!;
  String get assign => _localizedValues[locale.languageCode]!['assign']!;
  String get nonAssigned {
    return _localizedValues[locale.languageCode]?['nonAssigned'] ??
        'Not assigned';
  }
  String get sender => _localizedValues[locale.languageCode]!['sender']!;
  String get driver => _localizedValues[locale.languageCode]!['driver']!; // Ou 'Chauffeur' en français
  String get customerCreatedSuccess =>
      _localizedValues[locale.languageCode]!['customer_created_success']!;

  String get driverCreatedSuccess =>
      _localizedValues[locale.languageCode]!['driver_created_success']!;

  String get serverTimeout =>
      _localizedValues[locale.languageCode]!['server_timeout']!;

  String get orderActions => _localizedValues[locale.languageCode]!['order_actions']!;
  String get trackingViewDetails => _localizedValues[locale.languageCode]!['tracking_view_details']!;
  String get confirmOrder => _localizedValues[locale.languageCode]!['confirm_order']!;

  String get noOrdersYet => _localizedValues[locale.languageCode]!['no_orders_yet']!;
  String get userUpdatedSuccess => _localizedValues[locale.languageCode]?['user_updated_successfully'] ?? 'User Updated Success';
  String get shipmentList => _localizedValues[locale.languageCode]!['shipment_list']!;
  String get addNewCustomer => _localizedValues[locale.languageCode]?['add_new_customer'] ?? 'Add New Customer';
  String get addNewDriver => _localizedValues[locale.languageCode]?['add_new_driver'] ?? 'Add New Driver';
  String get editUserManagement => _localizedValues[locale.languageCode]?['edit_user_management'] ?? 'Edit User Management';
  String get editCustomer => _localizedValues[locale.languageCode]?['edit_customer'] ?? 'Edit Customer';
  String get next => _localizedValues[locale.languageCode]?['next'] ?? 'Next';
  String get previous => _localizedValues[locale.languageCode]?['previous'] ?? 'Previous';
  String get submit => _localizedValues[locale.languageCode]?['submit'] ?? 'Submit';
  String get userStatus => _localizedValues[locale.languageCode]?['user_status'] ?? 'User_Status';
  String get newsletterSubscription => _localizedValues[locale.languageCode]?['newsletter_subscription'] ?? 'Newsletter_Subscription';
  String get internalNotes => _localizedValues[locale.languageCode]?['internal_notes'] ?? 'Internal Notes';
  String get zipCode => _localizedValues[locale.languageCode]?['Zip_Code'] ?? 'Zip Code';
  String get superAdmins => _localizedValues[locale.languageCode]?['super_admins'] ?? 'Super Admins';
  String get userManagement => _localizedValues[locale.languageCode]?['user_management'] ?? 'User Management';
  String get drivers => _localizedValues[locale.languageCode]?['drivers'] ?? 'Drivers';
  String get customers => _localizedValues[locale.languageCode]?['customers'] ?? 'Customers';
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get users => _localizedValues[locale.languageCode]?['users'] ?? 'Users';
  String get noSuperAdminsFound => _localizedValues[locale.languageCode]!['no_super_admins_found']!;
  String get gender => _localizedValues[locale.languageCode]!['gender']!;
  String get office => _localizedValues[locale.languageCode]!['office']!;
  String get userLevel => _localizedValues[locale.languageCode]!['user_level']!;
  String get created => _localizedValues[locale.languageCode]!['created']!;
  String get notSpecified => _localizedValues[locale.languageCode]!['not_specified']!;
  String get active => _localizedValues[locale.languageCode]!['active']!;
  String get inactive => _localizedValues[locale.languageCode]!['inactive']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get addressesOf => _localizedValues[locale.languageCode]!['addresses_of']!;
  String get noAddressFound => _localizedValues[locale.languageCode]!['no_address_found']!;
  String get confirmDeletion => _localizedValues[locale.languageCode]!['confirm_deletion']!;
  String get deleteUserConfirm => _localizedValues[locale.languageCode]!['delete_user_confirm']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get userDeletedSuccess => _localizedValues[locale.languageCode]!['user_deleted_success']!;
  String get errorDeletingUser => _localizedValues[locale.languageCode]!['error_deleting_user']!;
  String get errorFetchingAddresses => _localizedValues[locale.languageCode]!['error_fetching_addresses']!;
  String get noUserManagementFound => _localizedValues[locale.languageCode]!['no_user_management_found']!;
  String userManagementLevel(int level) => _localizedValues[locale.languageCode]!['user_management_level']!.replaceFirst('{level}', level.toString());
  String get noDriversFound => _localizedValues[locale.languageCode]!['no_drivers_found']!;
  String get vehicleCode => _localizedValues[locale.languageCode]!['vehicle_code']!;
  String get vehicleRegistrationNumber => _localizedValues[locale.languageCode]!['vehicle_registration_number']!;
  String driverLevel(int level) => _localizedValues[locale.languageCode]!['driver_level']!.replaceFirst('{level}', level.toString());
  String get noCustomersFound => _localizedValues[locale.languageCode]!['no_customers_found']!;
  String get documentType => _localizedValues[locale.languageCode]!['document_type']!;
  String get documentNumber => _localizedValues[locale.languageCode]!['document_number']!;
  String customerLevel(int level) => _localizedValues[locale.languageCode]!['customer_level']!.replaceFirst('{level}', level.toString());
  String get addNewUserManagement => _localizedValues[locale.languageCode]!['add_new_user_management']!;
  String get personal => _localizedValues[locale.languageCode]!['personal']!;
  String get usernameRequired => _localizedValues[locale.languageCode]!['username_required']!;
  String get firstNameRequired => _localizedValues[locale.languageCode]!['first_name_required']!;
  String get lastNameRequired => _localizedValues[locale.languageCode]!['last_name_required']!;
  String get usernameMinLength => _localizedValues[locale.languageCode]!['username_min_length']!;
  String get invalidEmail => _localizedValues[locale.languageCode]!['invalid_email']!;
  String get addressRequired => _localizedValues[locale.languageCode]!['address_required']!;
  String get userCreatedSuccess => _localizedValues[locale.languageCode]!['user_created_success']!;
  String get noAddressesFound => _localizedValues[locale.languageCode]!['no_addresses_found']!;
  String get addAnotherAddress => _localizedValues[locale.languageCode]!['add_another_address']!;
  String get leavePasswordEmpty => _localizedValues[locale.languageCode]!['leave_password_empty']!;
  String get selectOffice => _localizedValues[locale.languageCode]!['select_Office']!;
  String get selectUserLevel => _localizedValues[locale.languageCode]!['select_user_level']!;
  String get country => _localizedValues[locale.languageCode]!['Country']!;

}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}