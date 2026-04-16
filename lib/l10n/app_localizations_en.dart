// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Welcome back! Please sign in to continue.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get loginButton => 'Log in';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get invalidEmail => 'Please enter a valid email address.';

  @override
  String get invalidPhone => 'Please enter a valid phone number.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters long.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get noAccountText => 'Don\'t have an account?';

  @override
  String get signUpText => 'Sign up';

  @override
  String get loginWithEmail => 'Email';

  @override
  String get loginWithPhone => 'Phone';

  @override
  String get loginMissingIdentifier => 'Please enter your email or phone number.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Choose how you want to sign up.';

  @override
  String get registerStep1Of3 => 'Step 1 of 3';

  @override
  String get registerWithEmail => 'Sign up with email';

  @override
  String get registerWithPhone => 'Sign up with phone';

  @override
  String get registerContinueButton => 'Continue';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get alreadyHaveAccountText => 'Already have an account?';

  @override
  String get verifyCodeTitle => 'Enter verification code';

  @override
  String get verifyCodeSubtitleEmail => 'We sent a code to your email.';

  @override
  String get verifyCodeSubtitlePhone => 'We sent a code to your phone.';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get invalidVerificationCode => 'Please enter a valid verification code.';

  @override
  String get verifyButtonLabel => 'Verify';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle => 'Pick a username and your real name.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters.';

  @override
  String get publicProfileLabel => 'Public profile';

  @override
  String get publicProfileDescription => 'If enabled, your profile and activities can be found by other users.';

  @override
  String get saveProfileButton => 'Save profile';

  @override
  String get profileCompletedSuccessMessage => 'Profile completed successfully. You can now log in.';

  @override
  String get profileCompletedErrorMessage => 'Failed to complete profile. Please try again.';

  @override
  String get featureComingSoon => 'This feature is coming soon.';

  @override
  String get changePhotoHint => 'Tap to add a profile photo';

  @override
  String get previousStepButton => 'Previous Step';

  @override
  String get completeProfileNamesTitle => 'Complete Your Profile - Names';

  @override
  String get completeProfileNamesSubtitle => 'Please provide your first and last name.';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get continueButton => 'Continue';

  @override
  String get completeProfileUsernameTitle => 'Complete Your Profile - Username';

  @override
  String get completeProfileUsernameSubtitle => 'Choose a unique username for your account.';

  @override
  String get completeProfilePhotoTitle => 'Complete Your Profile - Photo';

  @override
  String get completeProfilePhotoSubtitle => 'Add a profile picture to personalize your account.';

  @override
  String get nextStepButton => 'Next Step';

  @override
  String get home_welcome => 'Welcome 👋';

  @override
  String get home_search_hint => 'Search products, brands...';

  @override
  String get home_banner_title => 'Special Offers';

  @override
  String get home_banner_subtitle => 'Save up to 50% on selected items.';

  @override
  String get home_banner_button => 'Start shopping';

  @override
  String get home_items_default_title => 'Items';

  @override
  String get home_recommended_title => 'Recommended for you';

  @override
  String get home_popular_title => 'Popular now';

  @override
  String get home_bookings_title => 'Upcoming bookings';

  @override
  String get home_reviews_title => 'Latest reviews';

  @override
  String get home_flash_sale_title => 'Flash Sale';

  @override
  String get home_new_arrivals_title => 'New Arrivals';

  @override
  String get home_best_sellers_title => 'Best Sellers';

  @override
  String get home_top_rated_title => 'Top Rated';

  @override
  String get home_why_shop_title => 'Why Shop With Us';

  @override
  String get home_why_shop_free_shipping_title => 'Free Shipping';

  @override
  String get home_why_shop_free_shipping_subtitle => 'On all orders over \$50';

  @override
  String get home_why_shop_easy_returns_title => 'Easy Returns';

  @override
  String get home_why_shop_easy_returns_subtitle => '30-day return policy';

  @override
  String get home_why_shop_secure_payment_title => 'Secure Payment';

  @override
  String get home_why_shop_secure_payment_subtitle => '100% protected transactions';

  @override
  String get home_why_shop_support_title => '24/7 Support';

  @override
  String get home_why_shop_support_subtitle => 'Always here to help you';

  @override
  String get connection_offline => 'No internet connection';

  @override
  String get connection_server_down => 'Server is not responding';

  @override
  String get profile_login_required => 'Please log in to view your profile.';

  @override
  String get connection_issue => 'Connection issue';

  @override
  String get explore_title => 'Explore';

  @override
  String get explore_search_hint => 'Search ..';

  @override
  String get explore_items_title => 'All activities';

  @override
  String get explore_empty_message => 'No results found. Try another keyword.';

  @override
  String get explore_category_all => 'All';

  @override
  String explore_results_label(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get explore_sort_relevance => 'Relevance';

  @override
  String get explore_sort_price_low_high => 'Price: Low to High';

  @override
  String get explore_sort_price_high_low => 'Price: High to Low';

  @override
  String get explore_sort_date_soonest => 'Soonest date';

  @override
  String get profileMotto => 'Live your hobby!';

  @override
  String get profile_load_error => 'Couldn\'t load your profile. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get manageAccount => 'Manage account';

  @override
  String get profileMakePrivate => 'Make profile private';

  @override
  String get profileMakePublic => 'Make profile public';

  @override
  String get setInactive => 'Set account inactive';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get deactivate_title => 'Deactivate account';

  @override
  String get deactivate_warning => 'Enter your password to confirm deactivation.';

  @override
  String get current_password_label => 'Current password';

  @override
  String get language_note => 'Changing language will restart some screens.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get logout => 'Log out';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminDashboardSubtitle => 'Manage your app content and settings.';

  @override
  String get adminProductsTitle => 'Products';

  @override
  String get adminProductsEmpty => 'No products yet. Tap + to add your first product.';

  @override
  String get adminProductsNewArrivals => 'New arrivals';

  @override
  String get adminProductsBestSellers => 'Best sellers';

  @override
  String get adminProductsDiscounted => 'Discounted products';

  @override
  String get adminProductsSearchPlaceholder => 'Search products...';

  @override
  String get accountInactiveTitle => 'Your account is inactive';

  @override
  String get accountInactiveBody => 'Your account is currently inactive. Do you want to reactivate it to continue?';

  @override
  String get reactivateButton => 'Reactivate';

  @override
  String get accountReactivated => 'Your account has been reactivated successfully';

  @override
  String get chooseSignInRole => 'Choose how to sign in';

  @override
  String get enterAsOwner => 'Enter as Owner (Admin)';

  @override
  String get enterAsUser => 'Enter as User';

  @override
  String get roleLabel => 'Role';

  @override
  String get userLabel => 'User';

  @override
  String get loginInactiveTitle => 'Reactivate your account?';

  @override
  String loginInactiveMessage(Object name) {
    return 'Your account \"$name\" is currently inactive. Do you want to reactivate it and continue?';
  }

  @override
  String get loginInactiveReactivate => 'Reactivate';

  @override
  String get loginInactiveCancel => 'Not now';

  @override
  String get loginInactiveRequired => 'You must reactivate your account to sign in as user.';

  @override
  String get loginChooseRoleTitle => 'Choose how to sign in';

  @override
  String get loginEnterAsOwner => 'Enter as Owner (Admin)';

  @override
  String get loginEnterAsUser => 'Enter as User';

  @override
  String get loginRoleLabel => 'Role:';

  @override
  String get loginUserFallbackLabel => 'User';

  @override
  String get loginInactiveSuccess => 'Your account has been reactivated successfully.';

  @override
  String get productBadgeOnSale => 'On sale';

  @override
  String get productStatusDraft => 'Draft';

  @override
  String get productStatusActive => 'Active';

  @override
  String get productStatusArchived => 'Archived';

  @override
  String get errorNetworkNoInternet => 'No internet or server unreachable.';

  @override
  String get errorNetworkServerDown => 'The server is not responding. Please try again later.';

  @override
  String get errorServerUnexpected => 'Unexpected server error. Please try again.';

  @override
  String get errorUnexpected => 'Unexpected error. Please try again.';

  @override
  String get errorAuthUnauthorized => 'Your session has expired. Please log in again.';

  @override
  String get errorAuthForbidden => 'You don\'t have permission to perform this action.';

  @override
  String get logoutLabel => 'Logout';

  @override
  String get adminDashboardQuickActions => 'Quick actions';

  @override
  String get adminOverviewAnalytics => 'Overview & analytics';

  @override
  String get adminProjectsOwners => 'Projects & owners';

  @override
  String get adminUsersManagers => 'Users & managers';

  @override
  String get adminSettings => 'Settings';

  @override
  String adminSignedInAs(Object role) {
    return 'Signed in as $role';
  }

  @override
  String get adminProductCreateTitle => 'Create product';

  @override
  String get adminProductNameLabel => 'Name';

  @override
  String get adminProductNameHint => 'Ex: MacBook Pro';

  @override
  String get adminProductNameRequired => 'Name is required';

  @override
  String get adminProductDescriptionLabel => 'Description';

  @override
  String get adminProductDescriptionHint => 'Short description...';

  @override
  String get adminProductPriceLabel => 'Price';

  @override
  String get adminProductPriceRequired => 'Price is required';

  @override
  String get adminProductPriceInvalid => 'Price must be greater than 0';

  @override
  String get adminProductStockLabel => 'Stock';

  @override
  String get adminProductStatusLabel => 'Status';

  @override
  String get adminProductImageUrlLabel => 'Image URL';

  @override
  String get adminProductSkuLabel => 'SKU';

  @override
  String get adminProductTypeLabel => 'Product type';

  @override
  String get adminProductTypeSimple => 'Simple';

  @override
  String get adminProductTypeVariable => 'Variable';

  @override
  String get adminProductTypeGrouped => 'Grouped';

  @override
  String get adminProductTypeExternal => 'External';

  @override
  String get adminProductVirtualLabel => 'Virtual product';

  @override
  String get adminProductDownloadableLabel => 'Downloadable';

  @override
  String get adminProductDownloadUrlLabel => 'Download URL';

  @override
  String get adminProductExternalUrlLabel => 'External URL';

  @override
  String get adminProductButtonTextLabel => 'Button text';

  @override
  String get adminProductButtonTextHint => 'Buy now';

  @override
  String get adminProductSaleSectionTitle => 'Sale';

  @override
  String get adminProductSalePriceLabel => 'Sale price';

  @override
  String get adminProductSaleStartLabel => 'Sale start date';

  @override
  String get adminProductSaleEndLabel => 'Sale end date';

  @override
  String get adminProductAttributesTitle => 'Attributes';

  @override
  String get adminProductAttributeCodeLabel => 'Attribute code';

  @override
  String get adminProductAttributeValueLabel => 'Value';

  @override
  String get adminProductAddAttribute => 'Add attribute';

  @override
  String get adminProductEditTitle => 'Edit product';

  @override
  String get adminProductCategoryLabel => 'Category';

  @override
  String get adminProductItemTypeLabel => 'Item type';

  @override
  String get adminStockHint => 'Ex: 50';

  @override
  String get adminProductImageLabel => 'Image';

  @override
  String get adminProductPickImage => 'Pick image';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminProductSkuHint => 'Ex: SKU-123';

  @override
  String get adminProductDownloadUrlHint => 'https://...';

  @override
  String get adminProductExternalUrlHint => 'https://...';

  @override
  String get adminProductSaveButton => 'Save product';

  @override
  String get adminNoCategories => 'No categories found';

  @override
  String get adminCreateCategory => 'Create category';

  @override
  String get adminNoItemTypes => 'No item types found';

  @override
  String get adminCreateItemType => 'Create item type';

  @override
  String get adminTaxesTitle => 'Taxes';

  @override
  String get adminTaxRulesTitle => 'Tax Rules';

  @override
  String get adminTaxAddRule => 'Add tax rule';

  @override
  String get adminTaxNoRules => 'No tax rules found.';

  @override
  String get adminTaxCreateRuleTitle => 'Create Tax Rule';

  @override
  String get adminTaxEditRuleTitle => 'Edit Tax Rule';

  @override
  String get adminTaxRuleNameLabel => 'Rule name';

  @override
  String get adminTaxRuleNameHint => 'Ex: Standard VAT 11%';

  @override
  String get adminTaxRuleNameRequired => 'Tax rule name is required';

  @override
  String get adminTaxRuleRateLabel => 'Rate (%)';

  @override
  String get adminTaxRuleRateHint => '11.00';

  @override
  String get adminTaxRuleRateRequired => 'Rate is required';

  @override
  String get adminTaxRuleRateInvalid => 'Rate must be a valid number > 0';

  @override
  String get adminTaxAppliesToShippingLabel => 'Applies to shipping';

  @override
  String get adminTaxEnabledLabel => 'Enabled';

  @override
  String get adminTaxCountryIdLabel => 'Country ID (optional)';

  @override
  String get adminTaxCountryIdHint => '1';

  @override
  String get adminTaxRegionIdLabel => 'Region ID (optional)';

  @override
  String get adminTaxRegionIdHint => '2';

  @override
  String get adminTaxRateShort => 'Rate';

  @override
  String get adminTaxAppliesToShippingShort => 'Shipping tax';

  @override
  String get adminTaxEnabledShort => 'Enabled';

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminCreate => 'Create';

  @override
  String get adminUpdate => 'Update';

  @override
  String get adminEdit => 'Edit';

  @override
  String get adminDelete => 'Delete';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get adminSessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get adminTaxCountryLabel => 'Country';

  @override
  String get adminTaxCountryHint => 'Select country';

  @override
  String get adminTaxRegionLabel => 'Region';

  @override
  String get adminTaxSelectCountryFirst => 'Select country first';

  @override
  String get adminTaxRegionHint => 'Select region';

  @override
  String get adminTaxRulesTitleShort => 'Tax Rules';

  @override
  String get adminTaxRulesSubtitle => 'Manage tax rules for your products.';

  @override
  String get taxPreviewLoading => 'Calculating tax preview...';

  @override
  String get taxPreviewTitle => 'Tax Preview';

  @override
  String get itemsTaxLabel => 'Items Tax';

  @override
  String get shippingTaxLabel => 'Shipping Tax';

  @override
  String get totalTaxLabel => 'Total Tax';

  @override
  String get taxClassNone => 'No Tax';

  @override
  String get taxClassStandard => 'Standard Rate';

  @override
  String get taxClassReduced => 'Reduced Rate';

  @override
  String get taxClassZero => 'Zero Rate';

  @override
  String get taxClassLabel => 'Tax Class';

  @override
  String get taxClassHint => 'Select tax class';

  @override
  String get adminTaxCountryRequired => 'Country is required';

  @override
  String get adminTaxRegionRequired => 'Region is required';

  @override
  String get adminTaxRulePresetLabel => 'Rule Preset';

  @override
  String get adminTaxRulePresetHint => 'Select a preset to auto-fill fields';

  @override
  String get adminCustom => 'Custom';

  @override
  String get adminTaxAutoNameLabel => 'Auto-generate name';

  @override
  String get adminShippingTitle => 'Shipping Methods';

  @override
  String get adminShippingAdd => 'Add method';

  @override
  String get adminShippingNoMethods => 'No shipping methods yet';

  @override
  String get adminShippingCreateTitle => 'Create shipping method';

  @override
  String get adminShippingEditTitle => 'Edit shipping method';

  @override
  String get adminShippingNameLabel => 'Name';

  @override
  String get adminShippingNameRequired => 'Name is required';

  @override
  String get adminShippingDescLabel => 'Description';

  @override
  String get adminShippingTypeLabel => 'Method type';

  @override
  String get adminShippingTypeHint => 'Select type';

  @override
  String get adminShippingFlatRateLabel => 'Flat rate';

  @override
  String get adminShippingPerKgLabel => 'Price per kg';

  @override
  String get adminShippingThresholdLabel => 'Free shipping threshold';

  @override
  String get adminShippingCountryLabel => 'Country';

  @override
  String get adminShippingCountryHint => 'Select country';

  @override
  String get adminShippingCountryRequired => 'Country is required';

  @override
  String get adminShippingRegionLabel => 'Region';

  @override
  String get adminShippingRegionHint => 'Select region (optional)';

  @override
  String get adminShippingSelectCountryFirst => 'Select country first';

  @override
  String get adminShippingEnabledLabel => 'Enabled';

  @override
  String get adminShippingEnabledShort => 'Enabled';

  @override
  String get adminShippingTypeShort => 'Type';

  @override
  String get shippingTypeFlatRate => 'Flat rate';

  @override
  String get shippingTypeFree => 'Free';

  @override
  String get shippingTypeWeightBased => 'Weight based';

  @override
  String get shippingTypePriceBased => 'Price based';

  @override
  String get shippingTypePricePerKg => 'Price per kg';

  @override
  String get shippingTypeLocalPickup => 'Local pickup';

  @override
  String get shippingTypeFreeOverThreshold => 'Free over threshold';

  @override
  String get adminConfirmDelete => 'Are you sure you want to delete this item?';

  @override
  String get adminShippingCreateButton => 'Create method';

  @override
  String get adminDeleted => 'Deleted';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get adminEnabledOnly => 'Enabled only';

  @override
  String get adminShowAll => 'Show all';

  @override
  String get adminDisabled => 'Disabled only';

  @override
  String get adminActive => 'Active only';

  @override
  String get adminCreated => 'Created';

  @override
  String get adminUpdated => 'Updated';

  @override
  String get adminHomeBannersTitle => 'Home Banners';

  @override
  String get adminHomeBannerAdd => 'Add banner';

  @override
  String get adminHomeBannerNoBanners => 'No banners yet';

  @override
  String get adminHomeBannerCreateTitle => 'Create home banner';

  @override
  String get adminHomeBannerEditTitle => 'Edit home banner';

  @override
  String get adminHomeBannerTitleLabel => 'Title';

  @override
  String get adminHomeBannerSubtitleLabel => 'Subtitle';

  @override
  String get adminHomeBannerTargetTypeLabel => 'Target type';

  @override
  String get adminHomeBannerTargetIdLabel => 'Target ID';

  @override
  String get adminHomeBannerTargetUrlLabel => 'Target URL';

  @override
  String get adminHomeBannerSortOrderLabel => 'Sort order';

  @override
  String get adminHomeBannerActiveLabel => 'Active';

  @override
  String get adminImageLabel => 'Banner image';

  @override
  String get adminChooseFromGallery => 'Choose from gallery';

  @override
  String get adminTakePhoto => 'Take photo';

  @override
  String get adminRemoveImage => 'Remove';

  @override
  String get adminImageRequired => 'Image is required';

  @override
  String get adminTargetShort => 'Target';

  @override
  String get adminSortShort => 'Sort';

  @override
  String get adminUntitled => 'Untitled';

  @override
  String get adminHomeBannerEdit => 'Edit banner';

  @override
  String get adminHomeBannerCreate => 'Create banner';

  @override
  String get adminHomeBannerImageLabel => 'Banner image';

  @override
  String get adminHomeBannerImageRequired => 'Image is required';

  @override
  String get adminPickFromGallery => 'Gallery';

  @override
  String get adminPickFromCamera => 'Camera';

  @override
  String get adminHomeBannerSortLabel => 'Sort order';

  @override
  String get adminHomeBannerLoadingTargets => 'Loading targets...';

  @override
  String get adminHomeBannerTargetTypeHint => 'Select target type';

  @override
  String get adminHomeBannerTargetNone => 'None';

  @override
  String get adminHomeBannerTargetCategory => 'Category';

  @override
  String get adminHomeBannerTargetProduct => 'Product';

  @override
  String get adminHomeBannerTargetUrl => 'External URL';

  @override
  String get adminHomeBannerUrlRequired => 'URL is required';

  @override
  String get adminHomeBannerTargetCategoryLabel => 'Category';

  @override
  String get adminHomeBannerTargetCategoryHint => 'Select category';

  @override
  String get adminHomeBannerCategoryRequired => 'Category is required';

  @override
  String get adminHomeBannerTargetProductLabel => 'Product';

  @override
  String get adminHomeBannerTargetProductHint => 'Select product';

  @override
  String get adminHomeBannerProductRequired => 'Product is required';

  @override
  String get adminActiveLabel => 'Active';

  @override
  String get adminNoOptions => 'No options';

  @override
  String get noResultsLabel => 'No results';

  @override
  String get searchLabel => 'Search...';

  @override
  String get adminProductsSearchHint => 'Search products...';

  @override
  String get adminProductsFilterAll => 'All products';

  @override
  String get adminProductEditSubtitle => 'Update product details';

  @override
  String get adminProductCreateSubtitle => 'Add a new product';

  @override
  String get adminProductSectionBasicInfoTitle => 'Basic info';

  @override
  String get adminProductSectionPricingTitle => 'Pricing';

  @override
  String get adminProductSectionBasicInfoSubtitle => 'Name, description, type, SKU';

  @override
  String get adminProductSectionPricingSubtitle => 'Price, sale, stock';

  @override
  String get adminProductSectionMetaTitle => 'Product';

  @override
  String get adminProductSectionMetaSubtitle => 'SEO title & description';

  @override
  String get adminSelectCategoryFirst => 'Select category first';

  @override
  String get adminProductImageSectionTitle => 'Product image';

  @override
  String get adminProductImageSectionSubtitle => 'Upload product image';

  @override
  String get adminProductSectionConfigTitle => 'Product configuration';

  @override
  String get adminProductSectionConfigSubtitle => 'Virtual, downloadable, external';

  @override
  String get adminProductSaleSectionSubtitle => 'Set sale price and duration';

  @override
  String get adminProductAttributesSubtitle => 'Add custom attributes';

  @override
  String get cart_title => 'Shopping Cart';

  @override
  String get cart_empty_message => 'Your cart is empty. Start adding items!';

  @override
  String get cart_total_label => 'Total:';

  @override
  String get cart_checkout_button => 'Proceed to Checkout';

  @override
  String get cart_item_added => 'Item added to cart';

  @override
  String get cart_item_removed => 'Item removed from cart';

  @override
  String get cart_clear_confirmation => 'Are you sure you want to clear the cart?';

  @override
  String get cart_item_quantity_label => 'Quantity:';

  @override
  String get cart_item_updated => 'Cart item updated';

  @override
  String get cart_checkout => 'Checkout';

  @override
  String get cart_clear => 'Clear Cart';

  @override
  String get cart_empty_cta => 'Browse Products';

  @override
  String get cart_cleared => 'Cart has been cleared';

  @override
  String get adminProductNoAttributesHint => 'No attributes added yet.';

  @override
  String get cart_add_button => 'Add to Cart';

  @override
  String get home_book_now_button => 'Book Now';

  @override
  String get home_view_details_button => 'View Details';

  @override
  String get cart_login_required_title => 'Login Required';

  @override
  String get cart_login_required_message => 'Please log in to proceed to checkout.';

  @override
  String get cancel_button => 'Cancel';

  @override
  String get login_button => 'Log In';

  @override
  String get cart_item_added_snackbar => 'Item added to cart';

  @override
  String get coupons_title => 'Coupons';

  @override
  String get coupons_saved => 'Coupon saved successfully';

  @override
  String get coupons_deleted => 'Coupon deleted successfully';

  @override
  String get coupons_empty => 'No coupons yet. Create your first one!';

  @override
  String get coupons_type_percent => 'Percentage';

  @override
  String get coupons_type_fixed => 'Fixed amount';

  @override
  String get coupons_type_free_shipping => 'Free shipping';

  @override
  String get coupons_inactive_badge => 'Inactive';

  @override
  String get coupons_delete_title => 'Delete coupon';

  @override
  String coupons_delete_confirm(Object code) {
    return 'Are you sure you want to delete coupon $code?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get coupons_add => 'Add coupon';

  @override
  String get coupons_edit => 'Edit coupon';

  @override
  String get coupons_code => 'Code';

  @override
  String get coupons_code_required => 'Coupon code is required';

  @override
  String get coupons_description => 'Description';

  @override
  String get coupons_type => 'Discount type';

  @override
  String get coupons_value_percent => 'Discount (%)';

  @override
  String get coupons_value_amount => 'Discount amount';

  @override
  String get coupons_value_required => 'Discount value is required';

  @override
  String get coupons_value_invalid => 'Enter a valid discount value';

  @override
  String get coupons_max_uses => 'Max uses';

  @override
  String get coupons_min_order_amount => 'Min order amount';

  @override
  String get coupons_max_discount_amount => 'Max discount amount';

  @override
  String get coupons_active => 'Active';

  @override
  String get common_save => 'Save';

  @override
  String get adminCouponsTitle => 'Coupons';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutLoading => 'Loading checkout…';

  @override
  String get checkoutEmptyCart => 'Your cart is empty.';

  @override
  String get checkoutGoBack => 'Go back';

  @override
  String get checkoutItemsTitle => 'Items';

  @override
  String get checkoutAddressTitle => 'Shipping Address';

  @override
  String get checkoutCountryIdLabel => 'Country ID';

  @override
  String get checkoutCountryIdHint => 'Optional';

  @override
  String get checkoutRegionIdLabel => 'Region ID';

  @override
  String get checkoutRegionIdHint => 'Optional';

  @override
  String get checkoutCityLabel => 'City';

  @override
  String get checkoutCityHint => 'Enter city';

  @override
  String get checkoutPostalCodeLabel => 'Postal Code';

  @override
  String get checkoutPostalCodeHint => 'Optional';

  @override
  String get checkoutApplyAddress => 'Update shipping';

  @override
  String get checkoutCouponTitle => 'Coupon';

  @override
  String get checkoutCouponLabel => 'Coupon Code';

  @override
  String get checkoutCouponHint => 'Enter coupon (optional)';

  @override
  String get checkoutShippingTitle => 'Shipping';

  @override
  String get checkoutNoShippingMethods => 'No shipping methods found. Update address then refresh.';

  @override
  String get checkoutRefreshShipping => 'Refresh shipping';

  @override
  String get checkoutSelectShipping => 'Please select a shipping method';

  @override
  String get checkoutPaymentTitle => 'Payment';

  @override
  String get checkoutPaymentCash => 'Cash on delivery';

  @override
  String get checkoutStripeNote => 'Stripe requires payment confirmation (coming next).';

  @override
  String get checkoutSelectPayment => 'Please select a payment method';

  @override
  String get checkoutSummaryTitle => 'Order Summary';

  @override
  String get checkoutSubtotal => 'Subtotal';

  @override
  String get checkoutShipping => 'Shipping';

  @override
  String get checkoutTax => 'Tax';

  @override
  String get checkoutTotal => 'Total';

  @override
  String get checkoutPlaceOrder => 'Place Order';

  @override
  String get orderSummaryTitle => 'Order summary';

  @override
  String get secureCheckout => 'Secure checkout';

  @override
  String get itemsSubtotalLabel => 'Items subtotal';

  @override
  String get shippingLabel => 'Shipping';

  @override
  String get taxLabel => 'Tax';

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalLabel => 'Total';

  @override
  String get taxesShippingNote => 'Taxes and shipping are calculated based on your address.';

  @override
  String get searchHint => 'Search...';

  @override
  String get noOptions => 'No options';

  @override
  String get noResults => 'No results';

  @override
  String get missingUserToken => 'Missing user token';

  @override
  String itemNumber(int id) {
    return 'Item #$id';
  }

  @override
  String qtyPriceLine(int qty, String price) {
    return 'x$qty • $price';
  }

  @override
  String checkoutOrderPlacedToast(int orderId) {
    return 'Order placed ✅ (# $orderId)';
  }

  @override
  String orderTitle(int orderId) {
    return 'Order #$orderId';
  }

  @override
  String orderDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get orderItemsTitle => 'Items';

  @override
  String orderQtyUnitLine(int qty, String unit) {
    return 'Qty: $qty • Unit: $unit';
  }

  @override
  String get grandTotalLabel => 'Grand Total';

  @override
  String get downloadInvoicePdf => 'Download Invoice PDF';

  @override
  String get checkoutErrorCartEmpty => 'Cart is empty';

  @override
  String get checkoutErrorSelectPayment => 'Select a payment method';

  @override
  String get checkoutErrorSelectCountry => 'Select a country';

  @override
  String get checkoutErrorSelectRegion => 'Select a region';

  @override
  String get checkoutErrorEnterCity => 'Enter city';

  @override
  String get checkoutErrorEnterPostalCode => 'Enter postal code';

  @override
  String get checkoutErrorSelectShipping => 'Select a shipping method';

  @override
  String get checkoutErrorShippingMissing => 'Shipping method is missing';

  @override
  String get checkoutErrorStripeNotReady => 'Stripe not wired yet';

  @override
  String get commonDash => '-';

  @override
  String orderDetailsTitle(Object orderId) {
    return 'Order #$orderId';
  }

  @override
  String orderDetailsDateLine(Object date) {
    return 'Date: $date';
  }

  @override
  String get orderDetailsItemsTitle => 'Items';

  @override
  String orderDetailsItemFallback(Object itemId) {
    return 'Item #$itemId';
  }

  @override
  String orderDetailsQtyUnitLine(Object qty, Object unitPrice) {
    return 'Qty: $qty  •  Unit: $unitPrice';
  }

  @override
  String get orderDetailsSubtotal => 'Subtotal';

  @override
  String get orderDetailsShipping => 'Shipping';

  @override
  String get orderDetailsTax => 'Tax';

  @override
  String orderDetailsCouponLine(Object code) {
    return 'Coupon ($code)';
  }

  @override
  String get orderDetailsGrandTotal => 'Grand Total';

  @override
  String get orderDetailsDownloadInvoice => 'Download Invoice PDF';

  @override
  String common_stock_label(Object stock) {
    return 'Stock: $stock';
  }

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get ordersLoading => 'Loading your orders...';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody => 'When you place an order, it will show up here.';

  @override
  String get ordersReload => 'Reload';

  @override
  String get ordersFilterAll => 'All';

  @override
  String get ordersFilterPending => 'Pending';

  @override
  String get ordersFilterCompleted => 'Completed';

  @override
  String get ordersFilterCanceled => 'Canceled';

  @override
  String get ordersNoResultsForFilter => 'No orders match this filter.';

  @override
  String get ordersQtyLabel => 'Qty';

  @override
  String get ordersPaid => 'Paid';

  @override
  String get ordersUnpaid => 'Unpaid';

  @override
  String get ordersStatusPending => 'Pending';

  @override
  String get ordersStatusCompleted => 'Completed';

  @override
  String get ordersStatusCanceled => 'Canceled';

  @override
  String get ordersStatusUnknown => 'Unknown';

  @override
  String get ordersUnknownItem => 'Item';

  @override
  String get ordersQty => 'Qty';

  @override
  String get profileLoginRequired => 'Please log in to view your profile.';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get login => 'Login';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get profileLoadFailed => 'Failed to load profile.';

  @override
  String get username => 'Username';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get publicProfile => 'Public profile';

  @override
  String get save => 'Save';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get password => 'Password';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_empty_title => 'No notifications yet';

  @override
  String get notifications_empty_subtitle => 'When something happens, it’ll show up here. For now… peace and quiet 😌';

  @override
  String get notifications_retry => 'Retry';

  @override
  String get privacy_policy_title => 'Privacy Policy';

  @override
  String get privacy_policy_intro_title => 'Your privacy matters';

  @override
  String get privacy_policy_intro_body => 'This policy explains what we collect, why we collect it, and how you control your data.';

  @override
  String get privacy_policy_collect_title => 'What we collect';

  @override
  String get privacy_policy_collect_body => 'Basic profile info (name, email/phone), account settings, and app usage needed to provide the service.';

  @override
  String get privacy_policy_use_title => 'How we use your data';

  @override
  String get privacy_policy_use_body => 'To run the app, personalize your experience, improve features, and keep the platform secure.';

  @override
  String get privacy_policy_share_title => 'Sharing';

  @override
  String get privacy_policy_share_body => 'We don’t sell your data. We only share what’s needed with trusted services (like hosting) to operate the app.';

  @override
  String get privacy_policy_security_title => 'Security';

  @override
  String get privacy_policy_security_body => 'We use standard security practices, but no system is 100% perfect. Keep your password private.';

  @override
  String get privacy_policy_choices_title => 'Your choices';

  @override
  String get privacy_policy_choices_body => 'You can change visibility (public/private), update profile info, or request account actions based on the app features.';

  @override
  String get privacy_policy_contact_title => 'Contact';

  @override
  String get privacy_policy_contact_body => 'If you have questions about privacy, contact the app support team.';

  @override
  String get privacy_policy_last_updated => 'Last updated: Dec 19, 2025';

  @override
  String get home_bottom_slide_thankyou_title => 'THANK YOU';

  @override
  String get home_bottom_slide_thankyou_message => 'We appreciate your trust. Our team works daily to keep quality high and service fast.';

  @override
  String get home_bottom_slide_secure_title => 'SECURE & SAFE';

  @override
  String get home_bottom_slide_secure_message => 'Secure payments, controlled products, and clean packaging — the basics done right.';

  @override
  String get home_bottom_slide_support_title => 'REAL SUPPORT';

  @override
  String get home_bottom_slide_support_message => 'Need help? We reply. No “seen” and disappear vibes 😅';

  @override
  String get home_bottom_benefit_contact => 'CONTACT AN\nACCREDITED EXPERT';

  @override
  String get home_bottom_benefit_secure_payments => 'SECURED\nPAYMENTS';

  @override
  String get home_bottom_benefit_authentic_products => 'AUTHENTIC &\nCONTROLLED PRODUCTS';

  @override
  String home_bottom_benefit_free_delivery_above(String amount) {
    return 'FREE DELIVERY\nABOVE $amount';
  }

  @override
  String get home_trailing_limited_time => 'Limited time';

  @override
  String get home_trailing_see_all => 'See all';

  @override
  String get home_sale_tag => 'SALE';

  @override
  String home_stock_label(int count) {
    return 'Stock: $count';
  }

  @override
  String get home_bookings_placeholder => 'Bookings feed not wired yet.';

  @override
  String get home_footer_contact_title => 'Contact us';

  @override
  String get home_footer_contact_desc => 'Need help? We’re one message away.';

  @override
  String get home_footer_free_delivery_title => 'Free delivery';

  @override
  String get home_footer_free_delivery_desc => 'Available on selected orders and areas.';

  @override
  String get home_footer_returns_title => 'Easy returns';

  @override
  String get home_footer_returns_desc => 'Simple return policy on eligible items.';

  @override
  String get ownerPaymentSettingsTitle => 'Payment Methods';

  @override
  String get ownerPaymentSettingsDesc => 'Enable and configure gateways for this project';

  @override
  String get ownerPaymentConfigure => 'Configure';

  @override
  String get ownerPaymentIncomplete => 'Incomplete';

  @override
  String get ownerPaymentConfigHint => 'Configure fields below. Required fields must be filled.';

  @override
  String get paymentMethodsTitle => 'Payment Methods';

  @override
  String get paymentSearchHint => 'Search…';

  @override
  String get paymentNoResults => 'No results';

  @override
  String get paymentConfigure => 'Configure';

  @override
  String get paymentCancel => 'Cancel';

  @override
  String get paymentSave => 'Save';

  @override
  String get paymentFillFields => 'Fill the fields below, then Save.';

  @override
  String get paymentSavedKeepHint => 'Saved (leave empty to keep)';

  @override
  String get paymentRequiredLabel => '• required';

  @override
  String get paymentIncomplete => 'Incomplete';

  @override
  String get adminPaymentConfigTitle => 'Payment Methods';

  @override
  String get checkoutConfirmDialogTitle => 'Confirm checkout';

  @override
  String checkoutConfirmCartCleared(int itemCount) {
    String _temp0 = intl.Intl.pluralLogic(
      itemCount,
      locale: localeName,
      other: 'After checkout, your cart will become empty ($itemCount items).',
      one: 'After checkout, your cart will become empty (1 item).',
      zero: 'After checkout, your cart will become empty.',
    );
    return '$_temp0 Do you want to continue?';
  }

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get adminOrdersTitle => 'Orders';

  @override
  String get adminDashboard => 'Dashboard';

  @override
  String get adminAllTime => 'All time';

  @override
  String get adminLast7Days => 'Last 7 days';

  @override
  String get adminLast30Days => 'Last 30 days';

  @override
  String get adminClear => 'Clear';

  @override
  String get adminKpiOrders => 'Orders';

  @override
  String get adminKpiGrossSales => 'Gross Sales';

  @override
  String get adminKpiPaid => 'Paid';

  @override
  String get adminKpiOutstanding => 'Outstanding';

  @override
  String get adminKpiAvgOrder => 'Avg Order';

  @override
  String adminFullyPaidPercent(Object percent) {
    return 'Fully paid: $percent%';
  }

  @override
  String get adminPaidRevenueLast7Days => 'Paid revenue (last 7 days)';

  @override
  String get adminNoOrders => 'No orders';

  @override
  String get adminNoOrdersHint => 'Try changing the status filter, date range, or pull to refresh.';

  @override
  String get adminFilterAll => 'All';

  @override
  String adminOrderDetailsTitle(Object id) {
    return 'Order #$id';
  }

  @override
  String get adminOrderFailedToLoad => 'Failed to load order.';

  @override
  String get adminPaymentSummary => 'Payment Summary';

  @override
  String get adminOrderInfo => 'Order Info';

  @override
  String get adminStatus => 'Status';

  @override
  String get adminOrderTotal => 'Order Total';

  @override
  String get adminPaid => 'Paid';

  @override
  String get adminRemaining => 'Remaining';

  @override
  String get adminPaymentMethod => 'Payment Method';

  @override
  String get adminCurrency => 'Currency';

  @override
  String get adminShippingCity => 'Shipping City';

  @override
  String get adminShippingMethod => 'Shipping Method';

  @override
  String get adminCoupon => 'Coupon';

  @override
  String adminItemsCount(Object count) {
    return 'Items ($count)';
  }

  @override
  String get adminCustomer => 'Customer';

  @override
  String adminQtyPriceLine(Object qty, Object price) {
    return 'Qty: $qty  •  Price: $price';
  }

  @override
  String adminOrderCardTitle(Object id) {
    return 'Order #$id';
  }

  @override
  String adminItemsShort(Object count) {
    return '$count items';
  }

  @override
  String adminPaidShort(Object amount) {
    return 'Paid: $amount';
  }

  @override
  String adminRemainingShort(Object amount) {
    return 'Remaining: $amount';
  }

  @override
  String get adminFullyPaid => 'Fully paid';

  @override
  String get adminOrderStatusPending => 'Pending';

  @override
  String get adminOrderStatusCancelRequested => 'Cancel requested';

  @override
  String get adminOrderStatusCanceled => 'Canceled';

  @override
  String get adminOrderStatusRejected => 'Rejected';

  @override
  String get adminOrderStatusRefunded => 'Refunded';

  @override
  String get adminOrderStatusCompleted => 'Completed';

  @override
  String get adminMarkCashPaidBody => 'Are you sure you want to mark this order as paid in cash?';

  @override
  String get adminMarkCashPaid => 'Mark as paid in cash';

  @override
  String get adminMarkCashPaidTitle => 'Mark order as paid';

  @override
  String get adminMarkCashPaidButton => 'Mark as paid';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotSubtitle => 'Enter your email and we’ll send you a code.';

  @override
  String get forgotSendCode => 'Send code';

  @override
  String get forgotTip => 'Tip: check spam/junk folder too 👀';

  @override
  String get forgotVerifyTitle => 'Enter verification code';

  @override
  String forgotVerifySubtitle(Object email) {
    return 'We sent a code to $email';
  }

  @override
  String get forgotNewPassTitle => 'Set a new password';

  @override
  String get forgotNewPassSubtitle => 'Make it strong — future you will thank you.';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get savePasswordButton => 'Save password';

  @override
  String get codeLabel => 'Code';

  @override
  String get codeTooShort => 'Code is too short';

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get checkoutFullNameLabel => 'Full name';

  @override
  String get checkoutFullNameHint => ' your Name';

  @override
  String get checkoutAddressLineLabel => 'Street address';

  @override
  String get checkoutAddressLineHint => 'e.g. Building, floor, street name';

  @override
  String get checkoutPhoneLabel => 'Phone number';

  @override
  String get checkoutPhoneHint => 'e.g. +961 70 123 456';

  @override
  String get checkoutNotesLabel => 'Delivery notes (optional)';

  @override
  String get checkoutNotesHint => 'e.g. Call me when you arrive';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get postalCode => 'Postal code';

  @override
  String get adminShippingTotal => 'Shipping total';

  @override
  String get adminItemsTaxTotal => 'Items tax total';

  @override
  String get adminShippingTaxTotal => 'Shipping tax total';

  @override
  String get adminExcelImportTitle => 'Excel Import';

  @override
  String get adminExcelImportSubtitle => 'Import data using an Excel template prepared by Build4All.';

  @override
  String get adminExcelPickBtn => 'Pick';

  @override
  String get adminExcelFileLabel => 'Selected file';

  @override
  String get adminExcelNoFile => 'No Excel file selected yet';

  @override
  String get adminExcelValidateBtn => 'Validate Excel';

  @override
  String get adminExcelImportBtn => 'Import Data';

  @override
  String get adminExcelErrorsTitle => 'Errors';

  @override
  String get adminExcelWarningsTitle => 'Warnings';

  @override
  String get adminExcelReplaceTitle => 'Replace existing data';

  @override
  String get adminExcelReplaceHint => 'If enabled, we delete existing tenant data before importing the new file.';

  @override
  String get adminExcelReplaceScopeLabel => 'Replace scope';

  @override
  String get adminExcelProTipTitle => 'Pro tip';

  @override
  String get adminExcelProTipBody => ' Always validate the Excel file before importing to avoid partial or invalid data.';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get adminExcelDownloadTemplateBtn => 'Download Excel Template';

  @override
  String get adminExcelTemplateDownloaded => 'Excel template downloaded';

  @override
  String get adminExcelTemplateReadyMsg => 'Your Excel template is ready.';

  @override
  String get adminExcelOpenTemplateBtn => 'Open Template';

  @override
  String get adminExcelShareTemplateBtn => 'Share template';

  @override
  String get adminExcelShareTemplateHint => 'Share the Excel template via email or other apps.';

  @override
  String get adminExcelStep1Title => 'Step 1 · Download Template';

  @override
  String get adminExcelStep1Subtitle => 'Download the official Excel template, fill it, then upload it back.';

  @override
  String get adminExcelTemplateSavedToast => 'Excel template downloaded successfully';

  @override
  String get adminExcelSavedLocationTitle => 'Template saved';

  @override
  String get adminExcelSavedLocationBody => 'The Excel template has been saved locally on your device.';

  @override
  String get adminExcelStep2Title => 'Step 2 · Upload & Validate';

  @override
  String get adminExcelStep2Subtitle => 'Upload the filled Excel file and validate its content.';

  @override
  String get ai_chat_hint => 'Ask about this item…';

  @override
  String get ai_chat_suggested_question => 'Give me a quick summary and key details about this item.';

  @override
  String get ai_chat_error_send_failed => 'Failed to send message';

  @override
  String get ai_ask_button => 'Ask AI';

  @override
  String get common_sale_tag => 'SALE';

  @override
  String get common_description_title => 'Description';

  @override
  String get common_attributes_title => 'Attributes';

  @override
  String get common_sku_label => 'SKU';

  @override
  String get common_stock_label_plain => 'Stock';

  @override
  String get common_tax_label => 'Tax';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get ai_prompt_summary => 'Summarize this item';

  @override
  String get ai_prompt_features => 'What are the main features?';

  @override
  String get ai_prompt_best_use => 'Is this good for me?';

  @override
  String get outOfStock => 'Out Of Stock';

  @override
  String get authUsernameTaken => 'Username already in use.';

  @override
  String get authEmailAlreadyExists => 'This email is already registered.';

  @override
  String get authPhoneAlreadyExists => 'This phone number is already registered.';

  @override
  String get authUserNotFound => 'No account found for this email/phone.';

  @override
  String get authWrongPassword => 'Wrong password.';

  @override
  String get authInvalidCredentials => 'Invalid email/phone or password.';

  @override
  String get authAccountInactive => 'Your account is inactive. Reactivate to continue.';

  @override
  String get httpValidationError => 'Some fields are invalid.';

  @override
  String get httpConflict => 'Conflict. Please retry.';

  @override
  String get httpUnauthorized => 'Unauthorized.';

  @override
  String get httpForbidden => 'You don’t have permission to do this.';

  @override
  String get httpNotFound => 'Not found.';

  @override
  String get httpServerError => 'Server error. Please try later.';

  @override
  String get networkNoInternet => 'No internet connection.';

  @override
  String get networkTimeout => 'Request timed out.';

  @override
  String get networkError => 'Network error.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get adminMissingAdminToken => 'Session expired. Please log in again.';

  @override
  String get adminGenericError => 'Something went wrong. Please try again.';

  @override
  String get adminCategoryFallbackName => 'Category';

  @override
  String get adminItemTypeFallbackName => 'Item type';

  @override
  String get adminDeleteCategoryTitle => 'Delete category?';

  @override
  String adminDeleteCategoryMessage(String name) {
    return 'Delete \"$name\"?\n\nThis may also delete its item types (depending on backend rules).';
  }

  @override
  String get adminDeleteItemTypeTitle => 'Delete item type?';

  @override
  String adminDeleteItemTypeMessage(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get adminDeleteCategoryTooltip => 'Delete category';

  @override
  String get adminDeleteItemTypeTooltip => 'Delete item type';

  @override
  String get adminNewCategoryTitle => 'New category';

  @override
  String get adminNewCategoryHint => 'e.g. Laptops';

  @override
  String get adminNewItemTypeTitle => 'New item type';

  @override
  String get adminNewItemTypeHint => 'e.g. Laptop';

  @override
  String get adminSelectCategoryBeforeCreateItemType => 'Please select a category before creating an item type.';

  @override
  String get adminSelectCategoryBeforeSavingProduct => 'Please select a category before saving.';

  @override
  String get adminMissingCurrencyConfig => 'Currency is missing for this app. Configure currency first.';

  @override
  String get adminButtonTextDefaultAddToCart => 'Add to cart';

  @override
  String get adminPriceExampleHint => 'e.g. 120.00';

  @override
  String get commonDateFormatHint => 'YYYY-MM-DD';

  @override
  String get adminAttributeValueExampleHint => 'e.g. Samsung';

  @override
  String get adminProductAttributeValueHint => 'Ex: Samsung';

  @override
  String get adminDashboardHeroTitle => 'Dashboard';

  @override
  String adminDashboardAup(Object id) {
    return 'AUP $id';
  }

  @override
  String get retryLabel => 'Retry';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get sendRequestLabel => 'Send request';

  @override
  String get upgradeLabel => 'Upgrade';

  @override
  String get requestUpgradeLabel => 'Request upgrade';

  @override
  String get licenseChecking => 'Checking license…';

  @override
  String get licenseAccessGranted => 'Access granted ';

  @override
  String get licenseAccessBlocked => 'Access blocked';

  @override
  String licenseLimitReached(Object active, Object allowed) {
    return 'Limit reached: $active/$allowed users';
  }

  @override
  String get adminDashboardStatusChecking => 'Checking plan…';

  @override
  String get adminDashboardStatusLicenseFailed => 'License check failed';

  @override
  String get adminDashboardStatusLimitReached => 'User limit reached — upgrade required';

  @override
  String get adminDashboardStatusAccessBlocked => 'Access blocked';

  @override
  String get adminDashboardStatusOk => 'All systems go ';

  @override
  String adminDashboardActionsCount(Object count) {
    return '$count actions';
  }

  @override
  String get upgradeSheetTitle => 'Upgrade request';

  @override
  String get upgradeSheetSubtitle => 'Choose a plan to send a request.';

  @override
  String get noUpgradeAvailable => 'No upgrade available.';

  @override
  String get upgradeRequestSent => 'Request sent ';

  @override
  String get planGeneric => 'Plan';

  @override
  String get planFree => 'Free';

  @override
  String get planProHostedDb => 'Pro Hosted DB';

  @override
  String get planDedicated => 'Dedicated';

  @override
  String get planProHostedDbDesc => 'Unlimited users (hosted by Build4All)';

  @override
  String get planDedicatedDesc => 'Dedicated server (needs setup/assignment)';

  @override
  String get adminActionProductsSubtitle => 'Catalog & pricing';

  @override
  String get adminActionShippingSubtitle => 'Methods & fees';

  @override
  String get adminActionPaymentSubtitle => 'Stripe & setup';

  @override
  String get adminActionTaxesSubtitle => 'Tax rules';

  @override
  String get adminActionBannersSubtitle => 'Homepage banners';

  @override
  String get adminActionCouponsSubtitle => 'Discount codes';

  @override
  String get adminActionOrdersSubtitle => 'Manage & track';

  @override
  String get adminActionExcelSubtitle => 'Bulk import';

  @override
  String get adminProfileLoading => 'Loading profile…';

  @override
  String get adminMyProfileTitle => 'My profile';

  @override
  String adminMyProfileSubtitle(Object role) {
    return 'Signed in as $role';
  }

  @override
  String get manageProfileLabel => 'Manage';

  @override
  String get aupIdLabel => 'AUP ID';

  @override
  String get businessIdLabel => 'Business ID';

  @override
  String get profileLabel => 'Profile';

  @override
  String get adminIdLabel => 'Admin ID';

  @override
  String get copyLabel => 'Copy';

  @override
  String get copiedLabel => 'Copied ';

  @override
  String get closeLabel => 'Close';

  @override
  String get createdAtLabel => 'Created at';

  @override
  String get updatedAtLabel => 'Updated at';

  @override
  String get adminProductSaleDatesBothRequired => 'Please select both sale start and sale end dates.';

  @override
  String get adminProductSaleEndBeforeStart => 'Sale end date must be after the sale start date.';

  @override
  String get adminProductSaleStartInPast => 'Sale start date cannot be in the past.';

  @override
  String get adminProductSaleEndInPast => 'Sale end date cannot be in the past.';

  @override
  String get adminProductSalePriceRequiredForDates => 'Please enter a sale price when sale dates are set.';

  @override
  String get adminProductSalePriceInvalid => 'Sale price must be a valid number greater than 0.';

  @override
  String get adminProductSalePriceMustBeLess => 'Sale price must be less than the regular price.';

  @override
  String get adminProductSaleEndAutoCleared => 'Sale end date was cleared because it was before the start date.';

  @override
  String get forbiddenLabel => 'You don’t have permission to do this.';

  @override
  String get notFoundLabel => 'Not found.';

  @override
  String get serverErrorLabel => 'Server error. Please try again later.';

  @override
  String get networkErrorLabel => 'Network error. Please try again.';

  @override
  String get errPasswordLen6to8 => 'Password must be at least 6 characters';

  @override
  String get errPasswordNeedSpecial => 'Password must include at least 1 special character (e.g. !@#).';

  @override
  String get hintPasswordRuleOwner => 'Password must be at least 6 characters';

  @override
  String get msgProductDeleted => 'Product deleted successfully.';

  @override
  String get adminProductDeleteDialogTitle => 'Delete product';

  @override
  String adminProductDeleteDialogBody(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get adminProductDeleteSuccess => 'Product deleted successfully.';

  @override
  String get adminProductDeleteFailed => 'Failed to delete product.';

  @override
  String get adminProductDeleteBlockedCart => 'You can’t delete this product because it’s currently in customers’ carts. ';

  @override
  String get adminProductDeleteBlockedOrders => 'You can’t delete this product because it’s linked to existing orders. ';

  @override
  String get adminProductDeleteBlockedGeneric => 'You can’t delete this product because it’s linked to other records (orders or carts). ';

  @override
  String get errSessionExpired => 'Session expired. Please log in again.';

  @override
  String get errForbidden => 'You don’t have permission to perform this action.';

  @override
  String get errNotFound => 'Not found.';

  @override
  String adminProductsLoadFailed(Object details) {
    return 'Failed to load products.\n$details';
  }

  @override
  String adminProductsCountPill(Object filtered, Object total) {
    return '$filtered / $total';
  }

  @override
  String get adminCategoryDeleteSuccess => 'Category deleted successfully.';

  @override
  String get adminItemTypeDeleteSuccess => 'Item type deleted successfully.';

  @override
  String adminCategoryDeleteBlockedItems(Object count) {
    return 'You can’t delete this category because it’s used by $count item(s).';
  }

  @override
  String adminItemTypeDeleteBlockedItems(Object count) {
    return 'You can’t delete this item type because it’s used by $count item(s).';
  }

  @override
  String get adminCategoryDeleteBlockedGeneric => 'You can’t delete this category because it’s still being used.';

  @override
  String get adminItemTypeDeleteBlockedGeneric => 'You can’t delete this item type because it’s still being used.';

  @override
  String get adminConflictGeneric => 'This action can’t be completed right now.';

  @override
  String adminCategoryDeleteBlockedTypes(Object count) {
    return 'You can’t delete this category because it still has $count item type(s). Delete/move the types first.';
  }

  @override
  String get adminRejectOrderTitle => 'Reject order?';

  @override
  String get adminRejectOrderBody => 'This will mark the order as rejected. Continue?';

  @override
  String get adminRejectOrderButton => 'Reject Order';

  @override
  String get authGateContinueAs => 'Continue as…';

  @override
  String get authGateRoleAdminOwner => 'Admin / Owner';

  @override
  String get authGateRoleUser => 'User';

  @override
  String get appAccessTitleDeleted => 'Access Removed';

  @override
  String get appAccessTitleExpired => 'Subscription Expired';

  @override
  String get appAccessTitleUnavailable => 'App Unavailable';

  @override
  String get appAccessMessageDeleted => 'This app is no longer available.';

  @override
  String get appAccessMessageExpired => 'This app subscription has expired.';

  @override
  String get appAccessMessageUnavailable => 'You no longer have access to this app.';

  @override
  String get appAccessOwnerDisabledHint => 'This app has been disabled by the owner or is no longer active.';

  @override
  String get appAccessRetry => 'Retry';

  @override
  String get appAccessBlockedButton => 'Access blocked';

  @override
  String get pasteButtonLabel => 'Paste';

  @override
  String get codeReadyToVerifyHint => 'Code ready to verify';

  @override
  String get enterSixDigitCodeHint => 'Enter 6-digit verification code';

  @override
  String get accountAlreadyVerified => 'Account already verified. Please log in.';

  @override
  String ordersDetailsTitle(Object orderId) {
    return 'Order #$orderId';
  }

  @override
  String get ordersDetailsItemsTitle => 'Items';

  @override
  String get ordersDetailsQty => 'Qty';

  @override
  String get ordersDetailsUnit => 'Unit';

  @override
  String get ordersDetailsLineTotal => 'Total';

  @override
  String get ordersDetailsStatus => 'Status';

  @override
  String get ordersDetailsOrderTotal => 'Order Total';

  @override
  String get ordersDetailsPayment => 'Payment';

  @override
  String get ordersDetailsPaidAmount => 'Paid';

  @override
  String get ordersDetailsRemaining => 'Remaining';

  @override
  String get editProfile_emailLabel => 'Email';

  @override
  String get editProfile_invalidEmail => 'Invalid email format';

  @override
  String get editProfile_usernameInvalid => 'Username contains invalid characters';

  @override
  String get editProfile_codeSentTo => 'We sent a 6-digit code to:';

  @override
  String get editProfile_verifyNewEmailTitle => 'Verify new email';

  @override
  String get editProfile_codeLabel => 'Code';

  @override
  String get editProfile_codeRequired => 'Code required';

  @override
  String get editProfile_resend => 'Resend';

  @override
  String get editProfile_verify => 'Verify';

  @override
  String get editProfile_change => 'Change';

  @override
  String get editProfile_remove => 'Remove';

  @override
  String get editProfile_codeSentToast => 'Verification code sent to your new email';

  @override
  String get editProfile_emailUpdatedToast => 'Email updated successfully';

  @override
  String home_stock_left_label(int count) {
    return 'Only $count left';
  }

  @override
  String get editProfile_firstNameInvalid => 'First name contains invalid characters';

  @override
  String get editProfile_lastNameInvalid => 'Last name contains invalid characters';

  @override
  String get licenseDetailsTitle => 'License details';

  @override
  String get licensePlanLabel => 'Plan';

  @override
  String get licensePlanCodeLabel => 'Plan code';

  @override
  String get licenseStatusLabel => 'Status';

  @override
  String get licensePeriodEndLabel => 'Period end';

  @override
  String get licenseDaysLeftLabel => 'Days left';

  @override
  String get licenseUsersLabel => 'Users';

  @override
  String get licenseUsersRemainingLabel => 'Users remaining';

  @override
  String get licenseRequiresDedicatedLabel => 'Requires dedicated';

  @override
  String get licenseDedicatedInfraReadyLabel => 'Dedicated infra ready';

  @override
  String get licenseBlockingReasonLabel => 'Blocking reason';

  @override
  String get upgradeRequestPending => 'Upgrade request is pending approval';

  @override
  String get requestUpgradePendingLabel => 'Requested';

  @override
  String get upgradeRequestStatusLabel => 'Upgrade request status';

  @override
  String get upgradeRequestPlanLabel => 'Requested plan';

  @override
  String get upgradeRequestAtLabel => 'Requested at';

  @override
  String get upgradeRequestNoteLabel => 'Decision note';

  @override
  String get upgradeStatusPending => 'Pending';

  @override
  String get upgradeStatusApproved => 'Approved';

  @override
  String get upgradeStatusRejected => 'Rejected';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get checkoutCouponChecking => 'Checking coupon…';

  @override
  String get checkoutCouponApplied => 'Coupon applied';

  @override
  String checkoutCouponAppliedDiscount(String discount) {
    return 'Applied • -$discount';
  }

  @override
  String get checkoutCouponInvalid => 'Invalid coupon';

  @override
  String get checkoutCouponFailed => 'Coupon could not be applied.';

  @override
  String checkoutOrderPlacedWithCode(String code) {
    return 'Order placed: $code';
  }

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get checkoutCartEmptyError => 'Your cart is empty';

  @override
  String get checkoutPaymentMissingCode => 'Payment method code is missing';

  @override
  String get checkoutCountryRequiredError => 'Select a country';

  @override
  String get checkoutRegionRequiredError => 'Select a region';

  @override
  String get checkoutCityRequiredError => 'Enter city';

  @override
  String get checkoutAddressRequiredError => 'Enter address';

  @override
  String get checkoutPhoneRequiredError => 'Enter phone';

  @override
  String get checkoutShippingMissingError => 'Shipping method is missing';

  @override
  String get checkoutStripeCanceled => 'Payment canceled';

  @override
  String get checkoutStripeClientSecretMissing => 'Checkout did not return Stripe client secret';

  @override
  String get checkoutStripePublishableKeyMissing => 'Checkout did not return Stripe publishable key';

  @override
  String get home_support_sheet_title => 'Contact support';

  @override
  String get home_support_option_whatsapp => 'WhatsApp';

  @override
  String get home_support_option_email => 'Email';

  @override
  String get home_support_not_configured => 'Support contact details are not configured.';

  @override
  String get home_support_email_not_configured => 'Support email is not configured.';

  @override
  String get home_support_phone_not_configured => 'Support phone number is not configured.';

  @override
  String get home_support_open_email_failed => 'Could not open email app.';

  @override
  String get home_support_open_whatsapp_failed => 'Could not open WhatsApp.';

  @override
  String get home_support_invalid_phone => 'Invalid support number.';

  @override
  String get checkoutBlockedTitle => 'Checkout blocked';

  @override
  String get adminTaxRuleRateMustBePositive => 'Rate must be 0 or more';

  @override
  String get adminTaxRuleRateTooHigh => 'Rate cannot be greater than 100%';

  @override
  String get checkoutCouponExpired => 'Coupon expired.';

  @override
  String get checkoutCouponUsageLimitReached => 'Coupon usage limit reached.';

  @override
  String get checkoutCouponMinimumNotReached => 'Minimum order amount not reached for this coupon.';

  @override
  String get checkoutCouponDidNotAffectOrder => 'Coupon did not affect this order.';

  @override
  String get adminProductStatusSectionTitle => 'Product status';

  @override
  String get adminProductStatusSectionSubtitle => 'Control product visibility and lifecycle';

  @override
  String get adminProductStatusUnavailable => 'No statuses available';

  @override
  String get adminProductStatusRequired => 'Please select a product status';

  @override
  String get home_coming_soon_button => 'Coming Soon';

  @override
  String get connection_reconnecting => 'Connecting...';

  @override
  String get adminProductSectionSaleTitle => 'Sale settings';

  @override
  String get adminProductSectionSaleSubtitle => 'Configure sale price and sale period.';

  @override
  String get adminProductLoadingCategories => 'Loading categories...';

  @override
  String get adminProductLoadingItemTypes => 'Loading item types...';

  @override
  String get adminProductSelectCategoryHint => 'Select a category';

  @override
  String get adminProductSelectItemTypeHint => 'Select an item type';

  @override
  String get adminProductSectionCategoryTypeTitle => 'Category & type';

  @override
  String get adminProductSectionCategoryTypeSubtitle => 'Select the category and item type for this product';

  @override
  String get adminCreateCategoryTooltip => 'Create new category';

  @override
  String get adminCreateItemTypeTooltip => 'Create new item type';

  @override
  String get adminProductSalePriceHint => 'e.g. 99.99';

  @override
  String get adminProductSaleStartHint => 'Select sale start date';

  @override
  String get adminProductSaleEndHint => 'Select sale end date';

  @override
  String get checkoutPaymentMethodUnavailable => 'Selected payment method is not available,please call support';

  @override
  String get adminDisable => 'Disable';

  @override
  String get adminDisableShippingMethodMessage => 'Are you sure you want to disable this shipping method? It will no longer appear at checkout.';

  @override
  String get adminShippingMethodDisabled => 'Shipping method disabled successfully';

  @override
  String get adminDisabledLabel => 'Disabled';

  @override
  String get adminDisabledOnly => 'Disabled only';

  @override
  String get adminAllLabel => 'All';

  @override
  String get openLinkLabel => 'Open Link';

  @override
  String get downloadNowLabel => 'Download';

  @override
  String get downloadLabel => 'Download';

  @override
  String get downloadReadyLabel => 'Ready to download';

  @override
  String get downloadAfterPurchaseLabel => 'Available after purchase';

  @override
  String get externalProductLabel => 'External product';

  @override
  String get productTypeLabel => 'Product type';

  @override
  String get invalidExternalUrlLabel => 'Invalid external URL';

  @override
  String get missingExternalUrlLabel => 'Missing external URL';

  @override
  String get couldNotOpenLinkLabel => 'Could not open the link';

  @override
  String get invalidDownloadUrlLabel => 'Invalid download URL';

  @override
  String get missingDownloadUrlLabel => 'Missing download URL';

  @override
  String get couldNotStartDownloadLabel => 'Could not start the download';

  @override
  String get adminDownloadableMustBeSimple => 'Downloadable product must use Simple product type';

  @override
  String get adminDownloadableMustBeVirtual => 'Downloadable product must be virtual';

  @override
  String get adminDownloadUrlRequired => 'Download URL is required for downloadable product';

  @override
  String get adminExternalUrlRequired => 'External URL is required for external product';

  @override
  String get adminExternalCannotBeDownloadable => 'External product cannot be downloadable';

  @override
  String get adminDownloadableRulesHint => 'Downloadable products are saved as Simple + Virtual and require a download URL.';

  @override
  String get adminAllAttributeTypesAlreadyAdded => 'All available attribute types are already added';

  @override
  String get adminUploadFailed => 'failed to pick image';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonPrev => 'Previous';

  @override
  String get commonNext => 'Next';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonEnglish => 'English';

  @override
  String get commonFrench => 'Français';

  @override
  String get commonArabic => 'العربية';

  @override
  String get commonQty => 'Qty';

  @override
  String get commonFullName => 'Full Name';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonAddress => 'Address';

  @override
  String get commonCity => 'City';

  @override
  String get commonPostalCode => 'Postal Code';

  @override
  String get commonUnit => 'Unit';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonItem => 'Item';

  @override
  String get commonProvider => 'Provider';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonRef => 'Ref';

  @override
  String get commonCustomer => 'Customer';

  @override
  String get commonMethod => 'Method';

  @override
  String get commonRetry => 'Retry';

  @override
  String get adminOrderEditTitle => 'Edit Order';

  @override
  String get adminOrderEditRemoveHint => 'Set quantity to 0 to remove an item.';

  @override
  String adminOrderInvoiceDownloadFailed(Object error) {
    return 'Invoice download failed: $error';
  }

  @override
  String get adminOrderCannotEditMissingShipping => 'This order cannot be edited yet because shipping country or shipping method is missing in the order details response.';

  @override
  String get adminDashboardNotificationsTooltip => 'Notifications';

  @override
  String get adminProductSetMain => 'Set main';

  @override
  String get couponValidFrom => 'Valid From';

  @override
  String get couponValidTo => 'Valid To';

  @override
  String get excelReplaceScopeTenantSafe => 'TENANT (safe)';

  @override
  String get excelReplaceScopeFullDangerous => 'FULL (dangerous)';

  @override
  String get orderDetailsOrderCode => 'Order code';

  @override
  String get orderDetailsName => 'Name';

  @override
  String get orderDetailsPhone => 'Phone';

  @override
  String get orderDetailsAddress => 'Address';

  @override
  String get orderDetailsCity => 'City';

  @override
  String get orderDetailsPostalCode => 'Postal code';

  @override
  String get orderDetailsPayment => 'Payment';

  @override
  String get invoiceTitle => 'Invoice';

  @override
  String get invoiceItems => 'Items';

  @override
  String get invoiceOrder => 'Order';

  @override
  String get invoiceDate => 'Date';

  @override
  String get invoiceShipping => 'Shipping';

  @override
  String get invoiceSubtotal => 'Subtotal';

  @override
  String get invoiceTax => 'Tax';

  @override
  String get invoiceGrandTotal => 'Grand Total';

  @override
  String invoiceCouponLine(Object code) {
    return 'Coupon ($code)';
  }

  @override
  String get restoreLabel => 'Restore';

  @override
  String get restoreDeletedAccountTitle => 'Restore deleted account?';

  @override
  String get restoreDeletedAccountMessage => 'This account was deleted, but it can still be restored. Do you want to reactivate it now?';

  @override
  String get accountRestoredSuccessfully => 'Account restored successfully';

  @override
  String get adminOrderMarkPaid => 'Mark Paid';

  @override
  String get adminOrderComplete => 'Complete';

  @override
  String get adminOrderReject => 'Reject';

  @override
  String get adminOrderReopen => 'Reopen';

  @override
  String get adminOrderRestore => 'Restore';

  @override
  String get adminOrderSequenceLabel => 'Order Seq';

  @override
  String get adminOrderInternalIdLabel => 'Internal ID';

  @override
  String get adminPaymentMethodLabel => 'Payment Method';

  @override
  String get adminOrderCompleteTitle => 'Mark Completed';

  @override
  String get adminOrderCompleteBody => 'This will mark the order as completed.';

  @override
  String get adminOrderReopenTitle => 'Reopen (Cancel + Unpay)';

  @override
  String get adminOrderReopenBody => 'This will cancel the order and reset payment back to UNPAID.';

  @override
  String get adminOrderRestoreTitle => 'Restore to Pending';

  @override
  String get adminOrderRestoreBody => 'This will restore the order back to Pending.';

  @override
  String get commonSomethingWentWrongTryAgain => 'Something went wrong. Please try again.';

  @override
  String orderDetailsInvoiceDownloadFailed(Object error) {
    return 'Invoice download failed';
  }
}
