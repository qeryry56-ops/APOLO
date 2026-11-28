import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja')
  ];

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message seller...'**
  String get chatPlaceholder;

  /// No description provided for @chatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessageHint;

  /// No description provided for @chatRecordingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get chatRecordingPlaceholder;

  /// No description provided for @chatAddAttachmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get chatAddAttachmentTooltip;

  /// No description provided for @chatMessageInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Message input'**
  String get chatMessageInputLabel;

  /// No description provided for @chatSendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSendMessageTooltip;

  /// No description provided for @chatStagedAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Staged attachment: {name}'**
  String chatStagedAttachmentLabel(Object name);

  /// No description provided for @chatRemoveAttachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment {name}'**
  String chatRemoveAttachmentLabel(Object name);

  /// No description provided for @chatDismissMessageMenu.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Message Menu'**
  String get chatDismissMessageMenu;

  /// No description provided for @chatJumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get chatJumpToLatest;

  /// No description provided for @chatNewMessagesJumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'{count} new {messageWord}. Jump to latest'**
  String chatNewMessagesJumpToLatest(Object count, Object messageWord);

  /// No description provided for @chatMessageSingular.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get chatMessageSingular;

  /// No description provided for @chatMessagePlural.
  ///
  /// In en, this message translates to:
  /// **'messages'**
  String get chatMessagePlural;

  /// No description provided for @chatCallAndOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Call and chat options'**
  String get chatCallAndOptionsTooltip;

  /// No description provided for @chatSendFailedRetrySemantic.
  ///
  /// In en, this message translates to:
  /// **', Send failed, double tap to retry'**
  String get chatSendFailedRetrySemantic;

  /// No description provided for @chatSendingSemantic.
  ///
  /// In en, this message translates to:
  /// **', Sending'**
  String get chatSendingSemantic;

  /// No description provided for @chatEditedLabel.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get chatEditedLabel;

  /// No description provided for @chatRetrySendingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Retry sending message'**
  String get chatRetrySendingTooltip;

  /// No description provided for @chatTypingIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get chatTypingIndicatorLabel;

  /// No description provided for @chatPhotoPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get chatPhotoPreviewLabel;

  /// No description provided for @chatVoicePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get chatVoicePreviewLabel;

  /// No description provided for @voiceMicMutedIdleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mic muted. No audio detected. Hold mic button to record voice message'**
  String get voiceMicMutedIdleSemantic;

  /// No description provided for @voiceHoldToRecordSemantic.
  ///
  /// In en, this message translates to:
  /// **'Hold to record voice message. Slide left to cancel, slide up to lock hands-free'**
  String get voiceHoldToRecordSemantic;

  /// No description provided for @voiceMicMutedSuffixSemantic.
  ///
  /// In en, this message translates to:
  /// **'. Warning: Mic muted, no audio detected'**
  String get voiceMicMutedSuffixSemantic;

  /// No description provided for @voiceReleaseToCancelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel voice recording{mutedSuffix}'**
  String voiceReleaseToCancelSemantic(Object mutedSuffix);

  /// No description provided for @voiceLockedRecordingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Recording locked hands-free, {timeStr}{mutedSuffix}. Tap STOP to end recording'**
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix);

  /// No description provided for @voiceActiveRecordingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Recording voice message, {timeStr}{mutedSuffix}. Slide left to cancel, slide up to lock'**
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix);

  /// No description provided for @voiceWaveformMutedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Flat audio waveform, mic muted'**
  String get voiceWaveformMutedSemantic;

  /// No description provided for @voiceWaveformPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Interactive audio preview waveform'**
  String get voiceWaveformPreviewSemantic;

  /// No description provided for @voiceWaveformLiveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Live audio waveform'**
  String get voiceWaveformLiveSemantic;

  /// No description provided for @voiceMicMutedWarningSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mic muted warning. No audio detected.'**
  String get voiceMicMutedWarningSemantic;

  /// No description provided for @voiceMicMutedBadge.
  ///
  /// In en, this message translates to:
  /// **'Mic muted'**
  String get voiceMicMutedBadge;

  /// No description provided for @voiceCancelRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel voice recording'**
  String get voiceCancelRecordingTooltip;

  /// No description provided for @voicePauseRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause voice recording or preview'**
  String get voicePauseRecordingTooltip;

  /// No description provided for @voicePlayPreviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play voice preview'**
  String get voicePlayPreviewTooltip;

  /// No description provided for @voiceSendVoiceMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get voiceSendVoiceMessageTooltip;

  /// No description provided for @voiceReleaseToCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get voiceReleaseToCancelLabel;

  /// No description provided for @voiceSlideToCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get voiceSlideToCancelLabel;

  /// No description provided for @voiceHoldMicPrompt.
  ///
  /// In en, this message translates to:
  /// **'Hold mic to record voice message'**
  String get voiceHoldMicPrompt;

  /// No description provided for @voiceRecordButtonSemantic.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get voiceRecordButtonSemantic;

  /// No description provided for @voiceRecordGestureHint.
  ///
  /// In en, this message translates to:
  /// **'Tap or press and hold to record. Slide inward to cancel, slide up to lock'**
  String get voiceRecordGestureHint;

  /// No description provided for @voiceWaveformScrubberSemantic.
  ///
  /// In en, this message translates to:
  /// **'Voice message waveform scrubber'**
  String get voiceWaveformScrubberSemantic;

  /// No description provided for @voiceChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Chat'**
  String get voiceChatTitle;

  /// No description provided for @voiceMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record audio.'**
  String get voiceMicPermissionRequired;

  /// No description provided for @voiceCouldNotStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording on this device.'**
  String get voiceCouldNotStartRecording;

  /// No description provided for @voiceTapMicEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone below to record a voice message'**
  String get voiceTapMicEmptyPrompt;

  /// No description provided for @voiceTapMicInputHint.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to record voice note...'**
  String get voiceTapMicInputHint;

  /// No description provided for @voiceToggleWaveformTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle fitWidth / longScroll waveform'**
  String get voiceToggleWaveformTooltip;

  /// No description provided for @voiceToggleThemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle GTA 6 theme'**
  String get voiceToggleThemeTooltip;

  /// No description provided for @otpVerifyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your code'**
  String get otpVerifyCodeTitle;

  /// No description provided for @otpEnterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {destination}'**
  String otpEnterSixDigitCode(Object destination);

  /// No description provided for @otpCodeVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Code verified'**
  String get otpCodeVerifiedLabel;

  /// No description provided for @otpIncorrectCodeError.
  ///
  /// In en, this message translates to:
  /// **'Code incorrect, try again'**
  String get otpIncorrectCodeError;

  /// No description provided for @otpResendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendCodeCountdown(Object seconds);

  /// No description provided for @otpResendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendCodeButton;

  /// No description provided for @welcomeContinueAsGuestLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get welcomeContinueAsGuestLabel;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'example@gmail.com'**
  String get authEmailPlaceholder;

  /// No description provided for @authPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordPlaceholder;

  /// No description provided for @authFullNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authFullNamePlaceholder;

  /// No description provided for @authUsernameHandlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get authUsernameHandlePlaceholder;

  /// No description provided for @authPlainUsernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get authPlainUsernamePlaceholder;

  /// No description provided for @moroccoPhonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'+212 6XX XXX XXX'**
  String get moroccoPhonePlaceholder;

  /// No description provided for @likeButtonSemantic.
  ///
  /// In en, this message translates to:
  /// **'Like, {count} likes'**
  String likeButtonSemantic(Object count);

  /// No description provided for @unlikeButtonSemantic.
  ///
  /// In en, this message translates to:
  /// **'Unlike, {count} likes'**
  String unlikeButtonSemantic(Object count);

  /// No description provided for @likeSyncFailedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Failed to save like. Tap to retry'**
  String get likeSyncFailedSemantic;

  /// No description provided for @pullToRefreshRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing list'**
  String get pullToRefreshRefreshing;

  /// No description provided for @pullToRefreshRelease.
  ///
  /// In en, this message translates to:
  /// **'Release to refresh'**
  String get pullToRefreshRelease;

  /// No description provided for @pullToRefreshPullDown.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefreshPullDown;

  /// No description provided for @badgeOnlineSemantic.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get badgeOnlineSemantic;

  /// No description provided for @badgeUnreadNotificationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get badgeUnreadNotificationSemantic;

  /// No description provided for @badgeUnreadMaxSemantic.
  ///
  /// In en, this message translates to:
  /// **'99+ unread notifications'**
  String get badgeUnreadMaxSemantic;

  /// No description provided for @badgeUnreadCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count} unread {notificationWord}'**
  String badgeUnreadCountSemantic(Object count, Object notificationWord);

  /// No description provided for @notificationSingular.
  ///
  /// In en, this message translates to:
  /// **'notification'**
  String get notificationSingular;

  /// No description provided for @notificationPlural.
  ///
  /// In en, this message translates to:
  /// **'notifications'**
  String get notificationPlural;

  /// No description provided for @emojiReactWithSemantic.
  ///
  /// In en, this message translates to:
  /// **'React with {emoji}'**
  String emojiReactWithSemantic(Object emoji);

  /// No description provided for @emojiFewerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fewer emojis'**
  String get emojiFewerTooltip;

  /// No description provided for @emojiMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More emojis'**
  String get emojiMoreTooltip;

  /// No description provided for @listingFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favorite listing'**
  String get listingFavoriteTooltip;

  /// No description provided for @accommodationFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favorite accommodation'**
  String get accommodationFavoriteTooltip;

  /// No description provided for @listingBedroomsCount.
  ///
  /// In en, this message translates to:
  /// **'{bedrooms} bedrooms'**
  String listingBedroomsCount(Object bedrooms);

  /// No description provided for @listingTaxesIncluded.
  ///
  /// In en, this message translates to:
  /// **'taxes incl.'**
  String get listingTaxesIncluded;

  /// No description provided for @accommodationTotalForNights.
  ///
  /// In en, this message translates to:
  /// **'{total} total · {nights} nights'**
  String accommodationTotalForNights(Object total, Object nights);

  /// No description provided for @boostActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boostActionLabel;

  /// No description provided for @liveBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadgeLabel;

  /// No description provided for @meetingEncryptionKeyHint.
  ///
  /// In en, this message translates to:
  /// **'AES-GCM 256-bit Secret Key'**
  String get meetingEncryptionKeyHint;

  /// No description provided for @meetingDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Apolo Meeting'**
  String get meetingDefaultTitle;

  /// No description provided for @meetingDefaultParticipantName.
  ///
  /// In en, this message translates to:
  /// **'SFU Participant'**
  String get meetingDefaultParticipantName;

  /// No description provided for @bugReportSafetyHeader.
  ///
  /// In en, this message translates to:
  /// **'Apolo.ma Safety'**
  String get bugReportSafetyHeader;

  /// No description provided for @bugReportDescMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 5 characters.'**
  String get bugReportDescMinLengthError;

  /// No description provided for @bugReportNetworkFailedError.
  ///
  /// In en, this message translates to:
  /// **'Network request failed.'**
  String get bugReportNetworkFailedError;

  /// No description provided for @bugReportTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please check your connection and retry.'**
  String get bugReportTimeoutError;

  /// No description provided for @bugReportServerUnreachableError.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach Apolo.ma servers right now.'**
  String get bugReportServerUnreachableError;

  /// No description provided for @meetingSignInRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to join the meeting.'**
  String get meetingSignInRequiredError;

  /// No description provided for @meetingPermissionDeniedError.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this meeting.'**
  String get meetingPermissionDeniedError;

  /// No description provided for @meetingAlreadyEndedError.
  ///
  /// In en, this message translates to:
  /// **'This meeting has already ended.'**
  String get meetingAlreadyEndedError;

  /// No description provided for @meetingRoomLockedError.
  ///
  /// In en, this message translates to:
  /// **'This room is currently locked by the host.'**
  String get meetingRoomLockedError;

  /// No description provided for @meetingMaxCapacityError.
  ///
  /// In en, this message translates to:
  /// **'This meeting has reached its maximum participant capacity.'**
  String get meetingMaxCapacityError;

  /// No description provided for @meetingServiceUnreachableError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the meeting service. Check your connection.'**
  String get meetingServiceUnreachableError;

  /// No description provided for @accountOnboardingFormFinishSettingUpAccount.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up your account'**
  String get accountOnboardingFormFinishSettingUpAccount;

  /// No description provided for @accountOnboardingFormChooseCityInterestsYouCan.
  ///
  /// In en, this message translates to:
  /// **'Choose your city and interests. You can switch to a Business account for free anytime in Settings.'**
  String get accountOnboardingFormChooseCityInterestsYouCan;

  /// No description provided for @accountOnboardingFormCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get accountOnboardingFormCity;

  /// No description provided for @accountOnboardingFormChooseAtLeastOneInterest.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one interest'**
  String get accountOnboardingFormChooseAtLeastOneInterest;

  /// No description provided for @accountOnboardingFormSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & continue'**
  String get accountOnboardingFormSaveContinue;

  /// No description provided for @accountOnboardingFormReloadOptions.
  ///
  /// In en, this message translates to:
  /// **'Reload options'**
  String get accountOnboardingFormReloadOptions;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @sellItemButton.
  ///
  /// In en, this message translates to:
  /// **'Post Ad'**
  String get sellItemButton;

  /// No description provided for @navStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get navStores;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @featuredAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'VIP Ads'**
  String get featuredAdsTitle;

  /// No description provided for @latestAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Ads'**
  String get latestAdsTitle;

  /// No description provided for @allCitiesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCitiesFilter;

  /// No description provided for @allCategoriesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategoriesFilter;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @callSellerButton.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callSellerButton;

  /// No description provided for @whatsappButton.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappButton;

  /// No description provided for @chatInAppButton.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatInAppButton;

  /// No description provided for @boostAdButton.
  ///
  /// In en, this message translates to:
  /// **'Boost Ad'**
  String get boostAdButton;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @reportAdButton.
  ///
  /// In en, this message translates to:
  /// **'Report Ad'**
  String get reportAdButton;

  /// No description provided for @blockUserButton.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserButton;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a car, apartment, phone...'**
  String get searchHint;

  /// No description provided for @noAdsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No ads found matching your search'**
  String get noAdsFoundMessage;

  /// No description provided for @appStateDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appStateDark;

  /// No description provided for @appStateSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appStateSystem;

  /// No description provided for @appStateLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appStateLight;

  /// No description provided for @appStateApoloMember.
  ///
  /// In en, this message translates to:
  /// **'Apolo Member'**
  String get appStateApoloMember;

  /// No description provided for @appStateJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get appStateJustNow;

  /// No description provided for @appStateKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get appStateKm;

  /// No description provided for @bugReportReportTechnicalProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a technical problem'**
  String get bugReportReportTechnicalProblem;

  /// No description provided for @bugReportIfFeatureProductIsnT.
  ///
  /// In en, this message translates to:
  /// **'If a feature or product isn\'t working correctly, you can share feedback to help us improve Apolo.ma.'**
  String get bugReportIfFeatureProductIsnT;

  /// No description provided for @bugReportReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get bugReportReportProblem;

  /// No description provided for @bugReportReportsAboutAbuseSpamShouldn.
  ///
  /// In en, this message translates to:
  /// **'Reports about abuse or spam shouldn\'t be submitted here.'**
  String get bugReportReportsAboutAbuseSpamShouldn;

  /// No description provided for @bugReportLearnHowReportAbuseSpam.
  ///
  /// In en, this message translates to:
  /// **'Learn how to report abuse, spam, fraud, or policy and safety violations on Apolo.ma.'**
  String get bugReportLearnHowReportAbuseSpam;

  /// No description provided for @bugReportShakePhoneReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Shake phone to report a problem'**
  String get bugReportShakePhoneReportProblem;

  /// No description provided for @bugReportEnabledMobileSensorsDesktopBrowser.
  ///
  /// In en, this message translates to:
  /// **'Enabled for mobile sensors (desktop browser has no accelerometer)'**
  String get bugReportEnabledMobileSensorsDesktopBrowser;

  /// No description provided for @bugReportToggleEnable.
  ///
  /// In en, this message translates to:
  /// **'Toggle on to enable'**
  String get bugReportToggleEnable;

  /// No description provided for @bugReportToggleOffDisable.
  ///
  /// In en, this message translates to:
  /// **'Toggle off to disable'**
  String get bugReportToggleOffDisable;

  /// No description provided for @bugReportReportTechnicalProblem2.
  ///
  /// In en, this message translates to:
  /// **'Report technical problem'**
  String get bugReportReportTechnicalProblem2;

  /// No description provided for @bugReportLearnMoreAboutReportingAbuse.
  ///
  /// In en, this message translates to:
  /// **'Learn more about reporting abuse or spam'**
  String get bugReportLearnMoreAboutReportingAbuse;

  /// No description provided for @bugReportWouldYouLikeIncludeAdditional.
  ///
  /// In en, this message translates to:
  /// **'Would you like to include additional logs and diagnostics?'**
  String get bugReportWouldYouLikeIncludeAdditional;

  /// No description provided for @bugReportAlwaysCollectedBasicContext.
  ///
  /// In en, this message translates to:
  /// **'Always collected basic context:'**
  String get bugReportAlwaysCollectedBasicContext;

  /// No description provided for @bugReportAuthenticatedUserIdIfSigned.
  ///
  /// In en, this message translates to:
  /// **'Your authenticated user ID (if signed in), app version/build number, platform/OS, current screen/route name, and locale/RTL state.'**
  String get bugReportAuthenticatedUserIdIfSigned;

  /// No description provided for @bugReportOptionalDiagnosticsOnlyAttachedIf.
  ///
  /// In en, this message translates to:
  /// **'Optional diagnostics (only attached if you opt in):'**
  String get bugReportOptionalDiagnosticsOnlyAttachedIf;

  /// No description provided for @bugReportRecentMemoryLogBufferNavigation.
  ///
  /// In en, this message translates to:
  /// **'Recent in-memory log buffer, navigation and sanitized API error breadcrumbs, and device/viewport metadata to help reproduce the bug.'**
  String get bugReportRecentMemoryLogBufferNavigation;

  /// No description provided for @bugReportIncludeContinue.
  ///
  /// In en, this message translates to:
  /// **'Include and continue'**
  String get bugReportIncludeContinue;

  /// No description provided for @bugReportDonTIncludeContinue.
  ///
  /// In en, this message translates to:
  /// **'Don\'t include and continue'**
  String get bugReportDonTIncludeContinue;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @bugReportBrieflyExplainWhatHappenedWhat.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain what happened or what\'s not working.'**
  String get bugReportBrieflyExplainWhatHappenedWhat;

  /// No description provided for @bugReportScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get bugReportScreenshot;

  /// No description provided for @bugReportUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get bugReportUpload;

  /// No description provided for @bugReportRemoveScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove screenshot'**
  String get bugReportRemoveScreenshot;

  /// No description provided for @bugReportPreviewScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Preview screenshot'**
  String get bugReportPreviewScreenshot;

  /// No description provided for @bugReportAutoCaptureWasnTAvailable.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture wasn\'t available on this view — you can use Upload instead.'**
  String get bugReportAutoCaptureWasnTAvailable;

  /// No description provided for @bugReportPleaseDescribeWhatHappenedBefore.
  ///
  /// In en, this message translates to:
  /// **'Please describe what happened before sending.'**
  String get bugReportPleaseDescribeWhatHappenedBefore;

  /// No description provided for @bugReportPleaseWriteAtLeast5.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 5 characters to describe the issue.'**
  String get bugReportPleaseWriteAtLeast5;

  /// No description provided for @bugReportImageExceeds5MbMaximum.
  ///
  /// In en, this message translates to:
  /// **'Image exceeds the 5 MB maximum size limit.'**
  String get bugReportImageExceeds5MbMaximum;

  /// No description provided for @bugReportUnsupportedImageFormatPleaseChoose.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format. Please choose JPEG, PNG, or WebP.'**
  String get bugReportUnsupportedImageFormatPleaseChoose;

  /// No description provided for @bugReportCouldNotReadSelectedImage.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected image.'**
  String get bugReportCouldNotReadSelectedImage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @bugReportThanksTechnicalReportHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your technical report has been received (#{reportId})'**
  String bugReportThanksTechnicalReportHasBeen(Object reportId);

  /// No description provided for @bugReportThanksTechnicalReportHasBeen2.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your technical report has been received.'**
  String get bugReportThanksTechnicalReportHasBeen2;

  /// No description provided for @bugReportCouldNotSendReportRight.
  ///
  /// In en, this message translates to:
  /// **'Could not send the report right now. Check your connection and retry.'**
  String get bugReportCouldNotSendReportRight;

  /// No description provided for @bugReportTooManyReportsSentRecently.
  ///
  /// In en, this message translates to:
  /// **'Too many reports sent recently. Please retry in {seconds} seconds.'**
  String bugReportTooManyReportsSentRecently(Object seconds);

  /// No description provided for @bugReportTooManyReportsSentRecently2.
  ///
  /// In en, this message translates to:
  /// **'Too many reports sent recently. Please wait a moment and retry.'**
  String get bugReportTooManyReportsSentRecently2;

  /// No description provided for @bugReportReportingAbuseSpamSafetyIssues.
  ///
  /// In en, this message translates to:
  /// **'Reporting abuse, spam & safety issues'**
  String get bugReportReportingAbuseSpamSafetyIssues;

  /// No description provided for @bugReportThisFormIsStrictlyTechnical.
  ///
  /// In en, this message translates to:
  /// **'This form is strictly for technical bugs. To report suspicious listings, harassment, fraud, or policy violations on Apolo.ma, tap the Report option on that listing or chat, or open our safety reporting form below.'**
  String get bugReportThisFormIsStrictlyTechnical;

  /// No description provided for @bugReportOpenSafetyAbuseReport.
  ///
  /// In en, this message translates to:
  /// **'Open Safety & Abuse Report'**
  String get bugReportOpenSafetyAbuseReport;

  /// No description provided for @bugReportFoundBugBrokenScreenSend.
  ///
  /// In en, this message translates to:
  /// **'Found a bug or broken screen? Send a technical report with an optional screenshot.'**
  String get bugReportFoundBugBrokenScreenSend;

  /// No description provided for @meetingLobby.
  ///
  /// In en, this message translates to:
  /// **'Meeting Lobby'**
  String get meetingLobby;

  /// No description provided for @meetingNewGroupMeeting.
  ///
  /// In en, this message translates to:
  /// **'New Group Meeting'**
  String get meetingNewGroupMeeting;

  /// No description provided for @meetingJoinRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Join with Room Code'**
  String get meetingJoinRoomCode;

  /// No description provided for @meetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting Title'**
  String get meetingTitle;

  /// No description provided for @meetingEGLivePropertyWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'e.g. Live property walkthrough'**
  String get meetingEGLivePropertyWalkthrough;

  /// No description provided for @meetingRoomCodeApoXxxxXxxx.
  ///
  /// In en, this message translates to:
  /// **'Room code (apo-xxxx-xxxx)'**
  String get meetingRoomCodeApoXxxxXxxx;

  /// No description provided for @meetingJoinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get meetingJoinMeeting;

  /// No description provided for @meetingStartMeeting.
  ///
  /// In en, this message translates to:
  /// **'Start Meeting'**
  String get meetingStartMeeting;

  /// No description provided for @meetingEndEndEncryptionE2ee.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption (E2EE)'**
  String get meetingEndEndEncryptionE2ee;

  /// No description provided for @meetingSfuForwardsEncryptedPacketsWithout.
  ///
  /// In en, this message translates to:
  /// **'SFU forwards encrypted packets without ever seeing your media'**
  String get meetingSfuForwardsEncryptedPacketsWithout;

  /// No description provided for @meetingSharedRoomEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Shared Room Encryption Key'**
  String get meetingSharedRoomEncryptionKey;

  /// No description provided for @meetingAdaptiveSfuSvc25Participants.
  ///
  /// In en, this message translates to:
  /// **'Adaptive SFU + SVC (25+ participants)'**
  String get meetingAdaptiveSfuSvc25Participants;

  /// No description provided for @meetingMicOn.
  ///
  /// In en, this message translates to:
  /// **'Mic On'**
  String get meetingMicOn;

  /// No description provided for @meetingMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get meetingMuted;

  /// No description provided for @meetingCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get meetingCameraOn;

  /// No description provided for @meetingCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get meetingCameraOff;

  /// No description provided for @meetingShareScreen.
  ///
  /// In en, this message translates to:
  /// **'Share Screen'**
  String get meetingShareScreen;

  /// No description provided for @meetingStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing'**
  String get meetingStopSharing;

  /// No description provided for @meetingSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get meetingSpeaker;

  /// No description provided for @meetingFlipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip Camera'**
  String get meetingFlipCamera;

  /// No description provided for @meetingParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get meetingParticipants;

  /// No description provided for @meetingLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get meetingLeave;

  /// No description provided for @meetingEndAll.
  ///
  /// In en, this message translates to:
  /// **'End for All'**
  String get meetingEndAll;

  /// No description provided for @meetingUnstableNetworkAutomaticallyReconnectingVia.
  ///
  /// In en, this message translates to:
  /// **'Unstable network... Automatically reconnecting via UDP/TURN'**
  String get meetingUnstableNetworkAutomaticallyReconnectingVia;

  /// No description provided for @meetingLowBandwidthVideoLayersStepped.
  ///
  /// In en, this message translates to:
  /// **'Low bandwidth: video layers stepped down (SVC) to protect audio & battery'**
  String get meetingLowBandwidthVideoLayersStepped;

  /// No description provided for @meetingAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio Only'**
  String get meetingAudioOnly;

  /// No description provided for @meetingResumeVideo.
  ///
  /// In en, this message translates to:
  /// **'Resume Video'**
  String get meetingResumeVideo;

  /// No description provided for @meetingDataBatterySaverAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Data & battery saver (Audio-only) active'**
  String get meetingDataBatterySaverAudioOnly;

  /// No description provided for @meetingYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get meetingYou;

  /// No description provided for @meetingHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get meetingHost;

  /// No description provided for @meetingCoHost.
  ///
  /// In en, this message translates to:
  /// **'Co-host'**
  String get meetingCoHost;

  /// No description provided for @meetingLockRoom.
  ///
  /// In en, this message translates to:
  /// **'Lock Room'**
  String get meetingLockRoom;

  /// No description provided for @meetingUnlockRoom.
  ///
  /// In en, this message translates to:
  /// **'Unlock Room'**
  String get meetingUnlockRoom;

  /// No description provided for @meetingMuteMic.
  ///
  /// In en, this message translates to:
  /// **'Mute Mic'**
  String get meetingMuteMic;

  /// No description provided for @meetingRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get meetingRemove;

  /// No description provided for @meetingCopyInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Invite Link'**
  String get meetingCopyInviteLink;

  /// No description provided for @meetingInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied'**
  String get meetingInviteCopied;

  /// No description provided for @meetingConnectingSecureSfuMediaRouter.
  ///
  /// In en, this message translates to:
  /// **'Connecting to secure SFU media router...'**
  String get meetingConnectingSecureSfuMediaRouter;

  /// No description provided for @meetingPageCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String meetingPageCurrentTotal(Object current, Object total);

  /// No description provided for @accountSecurityEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get accountSecurityEnterValidEmailAddress;

  /// No description provided for @accountSecurityEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get accountSecurityEnterValidPhoneNumber;

  /// No description provided for @accountSecurityContactDetailsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact details updated successfully.'**
  String get accountSecurityContactDetailsUpdatedSuccessfully;

  /// No description provided for @accountSecurityPasswordMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get accountSecurityPasswordMustBeAtLeast;

  /// No description provided for @accountSecurityPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get accountSecurityPasswordsDoNotMatch;

  /// No description provided for @accountSecurityPasswordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get accountSecurityPasswordUpdatedSuccessfully;

  /// No description provided for @accountSecurityAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account security'**
  String get accountSecurityAccountSecurity;

  /// No description provided for @accountSecurityStayControlLogin.
  ///
  /// In en, this message translates to:
  /// **'Stay in control of your login'**
  String get accountSecurityStayControlLogin;

  /// No description provided for @accountSecurityUpdatePasswordEmailPhoneDirectly.
  ///
  /// In en, this message translates to:
  /// **'Update your password, email, or phone directly in the app.'**
  String get accountSecurityUpdatePasswordEmailPhoneDirectly;

  /// No description provided for @accountSecurityContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get accountSecurityContactDetails;

  /// No description provided for @accountSecurityEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get accountSecurityEmailAddress;

  /// No description provided for @accountSecurityPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get accountSecurityPhoneNumber;

  /// No description provided for @accountSecuritySaveContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Save contact details'**
  String get accountSecuritySaveContactDetails;

  /// No description provided for @accountSecurityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountSecurityChangePassword;

  /// No description provided for @accountSecurityCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountSecurityCurrentPassword;

  /// No description provided for @accountSecurityNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountSecurityNewPassword;

  /// No description provided for @accountSecurityConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get accountSecurityConfirmNewPassword;

  /// No description provided for @accountSecurityUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get accountSecurityUpdatePassword;

  /// No description provided for @accountSecuritySecurityOptions.
  ///
  /// In en, this message translates to:
  /// **'Security options'**
  String get accountSecuritySecurityOptions;

  /// No description provided for @accountSecuritySignUpdateThisInformation.
  ///
  /// In en, this message translates to:
  /// **'Sign in to update this information'**
  String get accountSecuritySignUpdateThisInformation;

  /// No description provided for @accountSetupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountSetupCreateAccount;

  /// No description provided for @accountSetupAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountSetupAccountType;

  /// No description provided for @accountSetupChooseAtLeastOneProfile.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one profile type to personalize your setup.'**
  String get accountSetupChooseAtLeastOneProfile;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @adDetailHiIsThisStillAvailable.
  ///
  /// In en, this message translates to:
  /// **'Hi, is this still available?'**
  String get adDetailHiIsThisStillAvailable;

  /// No description provided for @adDetailCouldNotUpdateFavoritesPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not update favorites. Please try again.'**
  String get adDetailCouldNotUpdateFavoritesPlease;

  /// No description provided for @adDetailPhoneNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get adDetailPhoneNumberCopied;

  /// No description provided for @adDetailCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get adDetailCopy;

  /// No description provided for @adDetailCouldNotStartConversationPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not start conversation. Please try again.'**
  String get adDetailCouldNotStartConversationPlease;

  /// No description provided for @adDetailUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get adDetailUserBlocked;

  /// No description provided for @adDetailReportThisListingAiContent.
  ///
  /// In en, this message translates to:
  /// **'Report this listing or AI content'**
  String get adDetailReportThisListingAiContent;

  /// No description provided for @adDetailQuickReviewByTrustSafety.
  ///
  /// In en, this message translates to:
  /// **'Quick review by our Trust & Safety team'**
  String get adDetailQuickReviewByTrustSafety;

  /// No description provided for @adDetailHideAllListingsFromThis.
  ///
  /// In en, this message translates to:
  /// **'Hide all listings from this seller'**
  String get adDetailHideAllListingsFromThis;

  /// No description provided for @adDetailDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get adDetailDetails;

  /// No description provided for @adDetailListingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Listing unavailable'**
  String get adDetailListingUnavailable;

  /// No description provided for @adDetailThisItemMayHaveBeen.
  ///
  /// In en, this message translates to:
  /// **'This item may have been sold or removed by the seller.'**
  String get adDetailThisItemMayHaveBeen;

  /// No description provided for @adDetailGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get adDetailGoBack;

  /// No description provided for @adDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adDetailCategory;

  /// No description provided for @adDetailCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get adDetailCondition;

  /// No description provided for @adDetailNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get adDetailNotSpecified;

  /// No description provided for @adDetailReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get adDetailReference;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @adDetailFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get adDetailFavorite;

  /// No description provided for @adDetailMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get adDetailMore;

  /// No description provided for @adDetailFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get adDetailFree;

  /// No description provided for @adDetailOnRequest.
  ///
  /// In en, this message translates to:
  /// **'On request'**
  String get adDetailOnRequest;

  /// No description provided for @negotiableBadge.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiableBadge;

  /// No description provided for @fixedPriceBadge.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get fixedPriceBadge;

  /// No description provided for @adDetailGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get adDetailGuests;

  /// No description provided for @adDetailBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get adDetailBedrooms;

  /// No description provided for @adDetailBeds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get adDetailBeds;

  /// No description provided for @adDetailBaths.
  ///
  /// In en, this message translates to:
  /// **'Baths'**
  String get adDetailBaths;

  /// No description provided for @adDetailGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get adDetailGood;

  /// No description provided for @adDetailRef.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get adDetailRef;

  /// No description provided for @adDetailViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get adDetailViews;

  /// No description provided for @adDetailGuestFavourite.
  ///
  /// In en, this message translates to:
  /// **'Guest favourite'**
  String get adDetailGuestFavourite;

  /// No description provided for @adDetailVideoTour.
  ///
  /// In en, this message translates to:
  /// **'Video tour'**
  String get adDetailVideoTour;

  /// No description provided for @adDetailJustListedMMAgo.
  ///
  /// In en, this message translates to:
  /// **'Just listed · {m}m ago'**
  String adDetailJustListedMMAgo(Object m);

  /// No description provided for @adDetailJustListedHHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Just listed · {h} hours ago'**
  String adDetailJustListedHHoursAgo(Object h);

  /// No description provided for @adDetailDDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{d} days ago'**
  String adDetailDDaysAgo(Object d);

  /// No description provided for @adDetailJustListed.
  ///
  /// In en, this message translates to:
  /// **'Just listed'**
  String get adDetailJustListed;

  /// No description provided for @adDetailBoostThisListing.
  ///
  /// In en, this message translates to:
  /// **'Boost this listing ⚡'**
  String get adDetailBoostThisListing;

  /// No description provided for @adDetailMessageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message seller'**
  String get adDetailMessageSeller;

  /// No description provided for @adDetailFastReply.
  ///
  /// In en, this message translates to:
  /// **'Fast reply'**
  String get adDetailFastReply;

  /// No description provided for @adDetailWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get adDetailWriteMessage;

  /// No description provided for @adDetailAlertsEnabledSimilarListings.
  ///
  /// In en, this message translates to:
  /// **'Alerts enabled for similar listings'**
  String get adDetailAlertsEnabledSimilarListings;

  /// No description provided for @adDetailAlertsPaused.
  ///
  /// In en, this message translates to:
  /// **'Alerts paused'**
  String get adDetailAlertsPaused;

  /// No description provided for @adDetailAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get adDetailAlerts;

  /// No description provided for @adDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adDetailMessage;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @adDetailNoDescriptionProvidedMessageSeller.
  ///
  /// In en, this message translates to:
  /// **'No description provided. Message the seller for details.'**
  String get adDetailNoDescriptionProvidedMessageSeller;

  /// No description provided for @adDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adDetailDescription;

  /// No description provided for @adDetailSeeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get adDetailSeeLess;

  /// No description provided for @adDetailSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get adDetailSeeMore;

  /// No description provided for @adDetailCallSeller.
  ///
  /// In en, this message translates to:
  /// **'Call seller'**
  String get adDetailCallSeller;

  /// No description provided for @adDetailApoloStoreCityname.
  ///
  /// In en, this message translates to:
  /// **'Apolo Store · {cityName}'**
  String adDetailApoloStoreCityname(Object cityName);

  /// No description provided for @adDetailApoloSellerCityname.
  ///
  /// In en, this message translates to:
  /// **'Apolo Seller · {cityName}'**
  String adDetailApoloSellerCityname(Object cityName);

  /// No description provided for @adDetailBusinessStore.
  ///
  /// In en, this message translates to:
  /// **'Business Store'**
  String get adDetailBusinessStore;

  /// No description provided for @adDetailSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get adDetailSeller;

  /// No description provided for @adDetailSeeReviews.
  ///
  /// In en, this message translates to:
  /// **'See reviews'**
  String get adDetailSeeReviews;

  /// No description provided for @followingButton.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingButton;

  /// No description provided for @followButton.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followButton;

  /// No description provided for @adDetailYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get adDetailYourRating;

  /// No description provided for @adDetailRateThisSeller.
  ///
  /// In en, this message translates to:
  /// **'Rate this seller'**
  String get adDetailRateThisSeller;

  /// No description provided for @adDetailEditReview.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get adDetailEditReview;

  /// No description provided for @adDetailWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get adDetailWriteReview;

  /// No description provided for @adDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get adDetailLocation;

  /// No description provided for @adDetailZoneDistkmKm.
  ///
  /// In en, this message translates to:
  /// **'In your zone · {distKm} km'**
  String adDetailZoneDistkmKm(Object distKm);

  /// No description provided for @adDetailDistkmKmAway.
  ///
  /// In en, this message translates to:
  /// **'{distKm} km away'**
  String adDetailDistkmKmAway(Object distKm);

  /// No description provided for @adDetailLocationIsApproximate.
  ///
  /// In en, this message translates to:
  /// **'Location is approximate'**
  String get adDetailLocationIsApproximate;

  /// No description provided for @adDetailFullMap.
  ///
  /// In en, this message translates to:
  /// **'Full map'**
  String get adDetailFullMap;

  /// No description provided for @adDetailRelatedSearches.
  ///
  /// In en, this message translates to:
  /// **'Related searches'**
  String get adDetailRelatedSearches;

  /// No description provided for @adDetailIfYouDonTLike.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t like this, you can '**
  String get adDetailIfYouDonTLike;

  /// No description provided for @adDetailHideThisListing.
  ///
  /// In en, this message translates to:
  /// **'hide this listing'**
  String get adDetailHideThisListing;

  /// No description provided for @adDetailWeLlShowYouFewer.
  ///
  /// In en, this message translates to:
  /// **' and we\'ll show you fewer listings like this.'**
  String get adDetailWeLlShowYouFewer;

  /// No description provided for @adDetailListingHiddenFromFeed.
  ///
  /// In en, this message translates to:
  /// **'Listing hidden from your feed'**
  String get adDetailListingHiddenFromFeed;

  /// No description provided for @adDetailListingRestored.
  ///
  /// In en, this message translates to:
  /// **'Listing restored'**
  String get adDetailListingRestored;

  /// No description provided for @adDetailHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get adDetailHidden;

  /// No description provided for @adDetailHideListing.
  ///
  /// In en, this message translates to:
  /// **'Hide listing'**
  String get adDetailHideListing;

  /// No description provided for @adDetailReportSafety.
  ///
  /// In en, this message translates to:
  /// **'Report & Safety'**
  String get adDetailReportSafety;

  /// No description provided for @adDetailSimilarListings.
  ///
  /// In en, this message translates to:
  /// **'Similar listings'**
  String get adDetailSimilarListings;

  /// No description provided for @adDetailAllReviews.
  ///
  /// In en, this message translates to:
  /// **'All Reviews'**
  String get adDetailAllReviews;

  /// No description provided for @adDetailSellerRating.
  ///
  /// In en, this message translates to:
  /// **'Seller rating'**
  String get adDetailSellerRating;

  /// No description provided for @adDetailEditReview2.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get adDetailEditReview2;

  /// No description provided for @adDetailWriteReview2.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get adDetailWriteReview2;

  /// No description provided for @adDetailSellerReviewsTotalcount.
  ///
  /// In en, this message translates to:
  /// **'Seller reviews ({totalCount})'**
  String adDetailSellerReviewsTotalcount(Object totalCount);

  /// No description provided for @adDetailShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get adDetailShowAll;

  /// No description provided for @adDetail5Stars.
  ///
  /// In en, this message translates to:
  /// **'5 stars'**
  String get adDetail5Stars;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @adDetailHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get adDetailHighest;

  /// No description provided for @adDetailSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get adDetailSort;

  /// No description provided for @adDetailNoWrittenReviewsSellernameYet.
  ///
  /// In en, this message translates to:
  /// **'No written reviews for {sellerName} yet'**
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName);

  /// No description provided for @adDetailHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get adDetailHelpful;

  /// No description provided for @addFriendsJoinMeApoloMaMorocco.
  ///
  /// In en, this message translates to:
  /// **'Join me on Apolo.ma — Morocco’s marketplace: https://apolo.ma'**
  String get addFriendsJoinMeApoloMaMorocco;

  /// No description provided for @addFriendsAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Add your friends'**
  String get addFriendsAddFriends;

  /// No description provided for @addFriendsInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get addFriendsInvited;

  /// No description provided for @addFriendsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get addFriendsInvite;

  /// No description provided for @addFriendsContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get addFriendsContacts;

  /// No description provided for @authUnableOpenGoogleSignRight.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Google sign-in right now.'**
  String get authUnableOpenGoogleSignRight;

  /// No description provided for @authUnableStartGoogleSign.
  ///
  /// In en, this message translates to:
  /// **'Unable to start Google sign-in.'**
  String get authUnableStartGoogleSign;

  /// No description provided for @authNoEmailAddressIsLinked.
  ///
  /// In en, this message translates to:
  /// **'No email address is linked to this account to receive the code.'**
  String get authNoEmailAddressIsLinked;

  /// No description provided for @authVerificationCodeWasSentMasked.
  ///
  /// In en, this message translates to:
  /// **'A verification code was sent to {masked}.'**
  String authVerificationCodeWasSentMasked(Object masked);

  /// No description provided for @authPleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authPleaseEnterValidEmailAddress;

  /// No description provided for @authPasswordMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters'**
  String get authPasswordMustBeAtLeast;

  /// No description provided for @authPleaseEnterNameAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name (at least 2 characters)'**
  String get authPleaseEnterNameAtLeast;

  /// No description provided for @authUsernameMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 letters or numbers'**
  String get authUsernameMustBeAtLeast;

  /// No description provided for @authPleaseEnterValidMoroccanPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Moroccan phone number (e.g. 650-123456)'**
  String get authPleaseEnterValidMoroccanPhone;

  /// No description provided for @authEnter6DigitVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code.'**
  String get authEnter6DigitVerificationCode;

  /// No description provided for @authNewVerificationCodeWasSent.
  ///
  /// In en, this message translates to:
  /// **'A new verification code was sent to {masked}.'**
  String authNewVerificationCodeWasSent(Object masked);

  /// No description provided for @authNewVerificationCodeWasSent2.
  ///
  /// In en, this message translates to:
  /// **'A new verification code was sent to your email.'**
  String get authNewVerificationCodeWasSent2;

  /// No description provided for @authBasevalueTriedAtHhMm.
  ///
  /// In en, this message translates to:
  /// **'{baseValue} (Tried at {hh}:{mm})'**
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm);

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButton;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEnterEmail;

  /// No description provided for @authEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authWhatSEmail.
  ///
  /// In en, this message translates to:
  /// **'What\'s your email?'**
  String get authWhatSEmail;

  /// No description provided for @authChoosePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get authChoosePassword;

  /// No description provided for @authWhatSFirstName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your first name?'**
  String get authWhatSFirstName;

  /// No description provided for @authPickUsername.
  ///
  /// In en, this message translates to:
  /// **'Pick a username'**
  String get authPickUsername;

  /// No description provided for @authOthersCanFindYouUsername.
  ///
  /// In en, this message translates to:
  /// **'Others can find you with your username!'**
  String get authOthersCanFindYouUsername;

  /// No description provided for @authWhatSPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'What\'s your phone number?'**
  String get authWhatSPhoneNumber;

  /// No description provided for @authEnterValidMoroccanPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Moroccan phone number to secure your account'**
  String get authEnterValidMoroccanPhoneNumber;

  /// No description provided for @authWeSent6DigitVerification.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to {maskedEmail}'**
  String authWeSent6DigitVerification(Object maskedEmail);

  /// No description provided for @authWeSent6DigitVerification2.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to your email'**
  String get authWeSent6DigitVerification2;

  /// No description provided for @authEnterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get authEnterVerificationCode;

  /// No description provided for @authSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get authSending;

  /// No description provided for @authResendCodeRemainingS.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({remaining}s)'**
  String authResendCodeRemainingS(Object remaining);

  /// No description provided for @businessSwitchWelcomeStoreApoloHowCan.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our store on Apolo! How can we help you today?'**
  String get businessSwitchWelcomeStoreApoloHowCan;

  /// No description provided for @businessSwitchPleaseEnterStoreNameAt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a store name (at least 2 characters).'**
  String get businessSwitchPleaseEnterStoreNameAt;

  /// No description provided for @businessSwitchPleaseEnterStoreName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your store name.'**
  String get businessSwitchPleaseEnterStoreName;

  /// No description provided for @businessSwitchBusinessProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Business profile updated!'**
  String get businessSwitchBusinessProfileUpdated;

  /// No description provided for @businessSwitchVerifiedBusinessStoreIsNow.
  ///
  /// In en, this message translates to:
  /// **'Your Verified Business store is now active!'**
  String get businessSwitchVerifiedBusinessStoreIsNow;

  /// No description provided for @businessSwitchCouldNotSaveBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save business profile. Please try again.'**
  String get businessSwitchCouldNotSaveBusinessProfile;

  /// No description provided for @businessSwitchBusinessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSwitchBusinessSettings;

  /// No description provided for @businessSwitchSwitchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Switch to Business'**
  String get businessSwitchSwitchBusiness;

  /// No description provided for @businessSwitchPreviousStoreDetailsAreReady.
  ///
  /// In en, this message translates to:
  /// **'Your previous store details are ready to reactivate!'**
  String get businessSwitchPreviousStoreDetailsAreReady;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingLabel;

  /// No description provided for @businessSwitchSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get businessSwitchSaveChanges;

  /// No description provided for @businessSwitchActivateFreeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Activate Free Business'**
  String get businessSwitchActivateFreeBusiness;

  /// No description provided for @businessSwitchWhatBestDescribesBusiness.
  ///
  /// In en, this message translates to:
  /// **'What best describes your business?'**
  String get businessSwitchWhatBestDescribesBusiness;

  /// No description provided for @businessSwitchThisCategoryBadgeAppearsUnder.
  ///
  /// In en, this message translates to:
  /// **'This category badge appears under your name on your profile and store.'**
  String get businessSwitchThisCategoryBadgeAppearsUnder;

  /// No description provided for @businessSwitchStoreIdentityHoursLocation.
  ///
  /// In en, this message translates to:
  /// **'Store identity, hours & location'**
  String get businessSwitchStoreIdentityHoursLocation;

  /// No description provided for @businessSwitchStoreAppearsStoresDirectoryOnce.
  ///
  /// In en, this message translates to:
  /// **'Your store appears in the Stores directory once you have at least 1 active listing.'**
  String get businessSwitchStoreAppearsStoresDirectoryOnce;

  /// No description provided for @businessSwitchStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store name *'**
  String get businessSwitchStoreName;

  /// No description provided for @businessSwitchEGAutoCasa.
  ///
  /// In en, this message translates to:
  /// **'e.g. Auto Casa'**
  String get businessSwitchEGAutoCasa;

  /// No description provided for @businessSwitchBioDescription.
  ///
  /// In en, this message translates to:
  /// **'Bio / Description'**
  String get businessSwitchBioDescription;

  /// No description provided for @businessSwitchTellCustomersAboutProductsService.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your products & service...'**
  String get businessSwitchTellCustomersAboutProductsService;

  /// No description provided for @businessSwitchCityAddress.
  ///
  /// In en, this message translates to:
  /// **'City & address'**
  String get businessSwitchCityAddress;

  /// No description provided for @businessSwitchEGMaarifCasablanca.
  ///
  /// In en, this message translates to:
  /// **'e.g. Maarif, Casablanca'**
  String get businessSwitchEGMaarifCasablanca;

  /// No description provided for @businessSwitchGoogleMapsLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Google Maps link (optional)'**
  String get businessSwitchGoogleMapsLinkOptional;

  /// No description provided for @businessSwitchWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get businessSwitchWorkingHours;

  /// No description provided for @businessSwitchContactDirectOrderTools.
  ///
  /// In en, this message translates to:
  /// **'Contact & direct order tools'**
  String get businessSwitchContactDirectOrderTools;

  /// No description provided for @businessSwitchEnable1TapOrdersAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Enable 1-tap orders and automatic chat greetings.'**
  String get businessSwitchEnable1TapOrdersAutomatic;

  /// No description provided for @businessSwitchBusinessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business phone'**
  String get businessSwitchBusinessPhone;

  /// No description provided for @businessSwitchEnableDirectOrderButtonStore.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Direct Order\" button on store'**
  String get businessSwitchEnableDirectOrderButtonStore;

  /// No description provided for @businessSwitchReceiveInstantOrdersCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Receive instant orders with customer details.'**
  String get businessSwitchReceiveInstantOrdersCustomerDetails;

  /// No description provided for @businessSwitchAutoGreetingMessageChat.
  ///
  /// In en, this message translates to:
  /// **'Auto-greeting message in Chat'**
  String get businessSwitchAutoGreetingMessageChat;

  /// No description provided for @businessSwitchWelcomeStoreHowCanWe.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our store! How can we help?'**
  String get businessSwitchWelcomeStoreHowCanWe;

  /// No description provided for @callIncomingVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming video call...'**
  String get callIncomingVideoCall;

  /// No description provided for @callIncomingVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming voice call...'**
  String get callIncomingVoiceCall;

  /// No description provided for @callRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get callRinging;

  /// No description provided for @callAllowMicCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow mic/camera access'**
  String get callAllowMicCameraAccess;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get callConnecting;

  /// No description provided for @callCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get callCalls;

  /// No description provided for @callCallsAreUnavailableThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Calls are unavailable on this device'**
  String get callCallsAreUnavailableThisDevice;

  /// No description provided for @callBackChat.
  ///
  /// In en, this message translates to:
  /// **'Back to Chat'**
  String get callBackChat;

  /// No description provided for @callVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get callVideoCall;

  /// No description provided for @callVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get callVoiceCall;

  /// No description provided for @callDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// No description provided for @callAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callAccept;

  /// No description provided for @callMic.
  ///
  /// In en, this message translates to:
  /// **'Mic'**
  String get callMic;

  /// No description provided for @callCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get callCamera;

  /// No description provided for @callEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get callEnd;

  /// No description provided for @chatListLastMessageLasttime.
  ///
  /// In en, this message translates to:
  /// **'Last message {lastTime}'**
  String chatListLastMessageLasttime(Object lastTime);

  /// No description provided for @chatListUnpinChat.
  ///
  /// In en, this message translates to:
  /// **'Unpin chat'**
  String get chatListUnpinChat;

  /// No description provided for @chatListPinChat.
  ///
  /// In en, this message translates to:
  /// **'Pin chat'**
  String get chatListPinChat;

  /// No description provided for @chatListChatUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Chat unpinned'**
  String get chatListChatUnpinned;

  /// No description provided for @chatListChatPinnedTop.
  ///
  /// In en, this message translates to:
  /// **'Chat pinned to top'**
  String get chatListChatPinnedTop;

  /// No description provided for @chatListMarkAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get chatListMarkAsRead;

  /// No description provided for @chatListUnmuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get chatListUnmuteNotifications;

  /// No description provided for @chatListMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatListMuteNotifications;

  /// No description provided for @chatListNotificationsUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications unmuted'**
  String get chatListNotificationsUnmuted;

  /// No description provided for @chatListChatMuted.
  ///
  /// In en, this message translates to:
  /// **'Chat muted'**
  String get chatListChatMuted;

  /// No description provided for @chatListArchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Archive chat'**
  String get chatListArchiveChat;

  /// No description provided for @chatListChatArchived.
  ///
  /// In en, this message translates to:
  /// **'Chat archived'**
  String get chatListChatArchived;

  /// No description provided for @chatListReportChat.
  ///
  /// In en, this message translates to:
  /// **'Report chat'**
  String get chatListReportChat;

  /// No description provided for @chatListBlockPeername.
  ///
  /// In en, this message translates to:
  /// **'Block {peerName}'**
  String chatListBlockPeername(Object peerName);

  /// No description provided for @chatListBlockedPeername.
  ///
  /// In en, this message translates to:
  /// **'Blocked {peerName}'**
  String chatListBlockedPeername(Object peerName);

  /// No description provided for @chatListDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatListDeleteChat;

  /// No description provided for @chatListChatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatListChatDeleted;

  /// No description provided for @chatListSelectConversationStartMessaging.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation to start messaging'**
  String get chatListSelectConversationStartMessaging;

  /// No description provided for @chatListChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatListChats;

  /// No description provided for @chatListMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get chatListMarkAllRead;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @chatListAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatListAll;

  /// No description provided for @chatListUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chatListUnread;

  /// No description provided for @chatListPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get chatListPinned;

  /// No description provided for @chatListSignViewChats.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your chats'**
  String get chatListSignViewChats;

  /// No description provided for @chatListMessageBuyersSellersDirectlySecurely.
  ///
  /// In en, this message translates to:
  /// **'Message buyers and sellers directly and securely.'**
  String get chatListMessageBuyersSellersDirectlySecurely;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @chatListNoUnreadChats.
  ///
  /// In en, this message translates to:
  /// **'No unread chats'**
  String get chatListNoUnreadChats;

  /// No description provided for @chatListNoPinnedChats.
  ///
  /// In en, this message translates to:
  /// **'No pinned chats'**
  String get chatListNoPinnedChats;

  /// No description provided for @chatListNoChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatListNoChatsYet;

  /// No description provided for @chatListBrowseListingsMessageSellersDirectly.
  ///
  /// In en, this message translates to:
  /// **'Browse listings and message sellers directly.'**
  String get chatListBrowseListingsMessageSellersDirectly;

  /// No description provided for @chatListExploreListings.
  ///
  /// In en, this message translates to:
  /// **'Explore listings'**
  String get chatListExploreListings;

  /// No description provided for @chatListPersonalMessagesAreEndEnd.
  ///
  /// In en, this message translates to:
  /// **'Your personal messages are end-to-end encrypted'**
  String get chatListPersonalMessagesAreEndEnd;

  /// No description provided for @chatRoomFailedLoadMessagesPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages. Please try again.'**
  String get chatRoomFailedLoadMessagesPleaseTry;

  /// No description provided for @chatRoomMessageEdited.
  ///
  /// In en, this message translates to:
  /// **'Message edited'**
  String get chatRoomMessageEdited;

  /// No description provided for @chatRoomDeletedEveryone.
  ///
  /// In en, this message translates to:
  /// **'Deleted for everyone'**
  String get chatRoomDeletedEveryone;

  /// No description provided for @chatRoomMessagePinned.
  ///
  /// In en, this message translates to:
  /// **'Message pinned'**
  String get chatRoomMessagePinned;

  /// No description provided for @chatRoomMessageUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Message unpinned'**
  String get chatRoomMessageUnpinned;

  /// No description provided for @chatRoomMessageStarred.
  ///
  /// In en, this message translates to:
  /// **'Message starred ⭐'**
  String get chatRoomMessageStarred;

  /// No description provided for @chatRoomStarRemoved.
  ///
  /// In en, this message translates to:
  /// **'Star removed'**
  String get chatRoomStarRemoved;

  /// No description provided for @chatRoomReportConversation.
  ///
  /// In en, this message translates to:
  /// **'Report conversation'**
  String get chatRoomReportConversation;

  /// No description provided for @chatRoomUserUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get chatRoomUserUnblocked;

  /// No description provided for @chatRoomUnblockPeername.
  ///
  /// In en, this message translates to:
  /// **'Unblock {peerName}'**
  String chatRoomUnblockPeername(Object peerName);

  /// No description provided for @chatRoomReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatRoomReply;

  /// No description provided for @chatRoomUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatRoomUnpin;

  /// No description provided for @chatRoomPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatRoomPin;

  /// No description provided for @chatRoomUnstar.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get chatRoomUnstar;

  /// No description provided for @chatRoomStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get chatRoomStar;

  /// No description provided for @chatRoomCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get chatRoomCopied;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @reportButton.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @chatRoomDeleteEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatRoomDeleteEveryone;

  /// No description provided for @chatRoomMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get chatRoomMorocco;

  /// No description provided for @chatRoomMyLocationResolvedcity.
  ///
  /// In en, this message translates to:
  /// **'📍 My location: {resolvedCity}'**
  String chatRoomMyLocationResolvedcity(Object resolvedCity);

  /// No description provided for @chatRoomPriceOfferTitleDhCleaned.
  ///
  /// In en, this message translates to:
  /// **'💰 Price offer for \"{title}\": DH {cleaned}'**
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned);

  /// No description provided for @chatRoomPriceOfferDhCleaned.
  ///
  /// In en, this message translates to:
  /// **'💰 Price offer: DH {cleaned}'**
  String chatRoomPriceOfferDhCleaned(Object cleaned);

  /// No description provided for @chatRoomCouldNotCaptureAudioPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not capture audio. Please allow microphone access and try again.'**
  String get chatRoomCouldNotCaptureAudioPlease;

  /// No description provided for @chatRoomVoiceMessageIsTooLong.
  ///
  /// In en, this message translates to:
  /// **'Voice message is too long. Please record a shorter message.'**
  String get chatRoomVoiceMessageIsTooLong;

  /// No description provided for @chatRoomThisMessageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatRoomThisMessageWasDeleted;

  /// No description provided for @chatRoomRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatRoomRead;

  /// No description provided for @chatRoomDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatRoomDelivered;

  /// No description provided for @chatRoomLastSeenClock.
  ///
  /// In en, this message translates to:
  /// **'Last seen {clock}'**
  String chatRoomLastSeenClock(Object clock);

  /// No description provided for @chatRoomOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatRoomOffline;

  /// No description provided for @chatRoomVideoCallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video Call — unavailable'**
  String get chatRoomVideoCallUnavailable;

  /// No description provided for @chatRoomVoiceCallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice Call — unavailable'**
  String get chatRoomVoiceCallUnavailable;

  /// No description provided for @chatRoomSafetyReport.
  ///
  /// In en, this message translates to:
  /// **'Safety & Report'**
  String get chatRoomSafetyReport;

  /// No description provided for @chatRoomYouBlockedThisUser.
  ///
  /// In en, this message translates to:
  /// **'You blocked this user'**
  String get chatRoomYouBlockedThisUser;

  /// No description provided for @chatRoomUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatRoomUnblock;

  /// No description provided for @chatRoomEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get chatRoomEditingMessage;

  /// No description provided for @chatRoomSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get chatRoomSendMessage;

  /// No description provided for @editProfileMinimum3CharactersRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters required'**
  String get editProfileMinimum3CharactersRequired;

  /// No description provided for @editProfileCleanIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'@{clean} is available'**
  String editProfileCleanIsAvailable(Object clean);

  /// No description provided for @editProfileAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'Already taken.'**
  String get editProfileAlreadyTaken;

  /// No description provided for @editProfileProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get editProfileProfilePhoto;

  /// No description provided for @editProfileChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get editProfileChooseFromLibrary;

  /// No description provided for @editProfileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get editProfileTakePhoto;

  /// No description provided for @editProfileRemoveCurrentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove current photo'**
  String get editProfileRemoveCurrentPhoto;

  /// No description provided for @editProfileChoosePresetAvatar.
  ///
  /// In en, this message translates to:
  /// **'Or choose a preset avatar'**
  String get editProfileChoosePresetAvatar;

  /// No description provided for @editProfileSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get editProfileSelectCity;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @editProfilePhoneWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Phone & WhatsApp'**
  String get editProfilePhoneWhatsapp;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @editProfileNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get editProfileNameIsRequired;

  /// No description provided for @editProfileUsernameMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters.'**
  String get editProfileUsernameMustBeAtLeast;

  /// No description provided for @editProfileThisUsernameIsAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get editProfileThisUsernameIsAlreadyTaken;

  /// No description provided for @editProfileCouldNotSaveChangesPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes. Please try again.'**
  String get editProfileCouldNotSaveChangesPlease;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileEditPicture.
  ///
  /// In en, this message translates to:
  /// **'Edit picture'**
  String get editProfileEditPicture;

  /// No description provided for @editProfileFullName.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get editProfileFullName;

  /// No description provided for @editProfileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsername;

  /// No description provided for @editProfileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editProfileBio;

  /// No description provided for @editProfileWriteShortBioAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Write a short bio about yourself...'**
  String get editProfileWriteShortBioAboutYourself;

  /// No description provided for @editProfileAddCity.
  ///
  /// In en, this message translates to:
  /// **'Add city'**
  String get editProfileAddCity;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhone;

  /// No description provided for @editProfileAddPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get editProfileAddPhoneNumber;

  /// No description provided for @editProfileManageStoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Manage store details'**
  String get editProfileManageStoreDetails;

  /// No description provided for @editProfileGetVerifiedBusinessStore.
  ///
  /// In en, this message translates to:
  /// **'Get Verified & Business Store'**
  String get editProfileGetVerifiedBusinessStore;

  /// No description provided for @editProfilePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get editProfilePersonalInformation;

  /// No description provided for @editProfileEmailPasswordSettings.
  ///
  /// In en, this message translates to:
  /// **'Email & password settings'**
  String get editProfileEmailPasswordSettings;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @forgotPasswordWeSent6DigitVerification.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to {masked}.'**
  String forgotPasswordWeSent6DigitVerification(Object masked);

  /// No description provided for @forgotPasswordPleaseEnter6DigitVerification.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code.'**
  String get forgotPasswordPleaseEnter6DigitVerification;

  /// No description provided for @forgotPasswordPasswordUpdatedSignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated and signed in successfully!'**
  String get forgotPasswordPasswordUpdatedSignedSuccessfully;

  /// No description provided for @forgotPasswordYouWillReceiveEmailSet.
  ///
  /// In en, this message translates to:
  /// **'You will receive an email to set a new password'**
  String get forgotPasswordYouWillReceiveEmailSet;

  /// No description provided for @forgotPasswordChooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get forgotPasswordChooseNewPassword;

  /// No description provided for @homeInternetConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Internet connection lost'**
  String get homeInternetConnectionLost;

  /// No description provided for @homeCheckNetworkConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and try again to load listings.'**
  String get homeCheckNetworkConnectionTryAgain;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @homeWelcomeApolo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Apolo'**
  String get homeWelcomeApolo;

  /// No description provided for @homeSearchCarsHomesPhonesAccounts.
  ///
  /// In en, this message translates to:
  /// **'Search cars, homes, phones, or accounts...'**
  String get homeSearchCarsHomesPhonesAccounts;

  /// No description provided for @homeLatestListings.
  ///
  /// In en, this message translates to:
  /// **'Latest listings'**
  String get homeLatestListings;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNoListingsWithinZoneradiuskmKm.
  ///
  /// In en, this message translates to:
  /// **'No listings within {zoneRadiusKm} km of {s} yet'**
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s);

  /// No description provided for @homeShowAllMorocco.
  ///
  /// In en, this message translates to:
  /// **'Show all Morocco'**
  String get homeShowAllMorocco;

  /// No description provided for @homeChangeZone.
  ///
  /// In en, this message translates to:
  /// **'Change zone'**
  String get homeChangeZone;

  /// No description provided for @homeBrowseAllListingsMorocco.
  ///
  /// In en, this message translates to:
  /// **'Browse all listings in Morocco'**
  String get homeBrowseAllListingsMorocco;

  /// No description provided for @home1MarketplaceMorocco.
  ///
  /// In en, this message translates to:
  /// **'#1 Marketplace in Morocco 🇲🇦'**
  String get home1MarketplaceMorocco;

  /// No description provided for @homeBuySellSafelyWithoutMiddlemen.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell safely without middlemen'**
  String get homeBuySellSafelyWithoutMiddlemen;

  /// No description provided for @homeCarsPhonesRealEstateDiscover.
  ///
  /// In en, this message translates to:
  /// **'Cars, phones, real estate. Discover listings near you.'**
  String get homeCarsPhonesRealEstateDiscover;

  /// No description provided for @homeExclusiveDeals.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Deals'**
  String get homeExclusiveDeals;

  /// No description provided for @homeWhyChooseApolo.
  ///
  /// In en, this message translates to:
  /// **'Why choose Apolo?'**
  String get homeWhyChooseApolo;

  /// No description provided for @home0CommissionFree.
  ///
  /// In en, this message translates to:
  /// **'0% Commission & Free'**
  String get home0CommissionFree;

  /// No description provided for @homeBuySellFreeZeroMiddlemen.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell for free with zero middlemen.'**
  String get homeBuySellFreeZeroMiddlemen;

  /// No description provided for @homeDirectChatCall.
  ///
  /// In en, this message translates to:
  /// **'Direct Chat & Call'**
  String get homeDirectChatCall;

  /// No description provided for @homeMessageSellerDirectlyMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Message the seller directly and make an offer in one tap.'**
  String get homeMessageSellerDirectlyMakeOffer;

  /// No description provided for @homeVerifiedListings.
  ///
  /// In en, this message translates to:
  /// **'Verified Listings'**
  String get homeVerifiedListings;

  /// No description provided for @homeContinuousReviewKeepAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'Continuous review to keep all transactions safe.'**
  String get homeContinuousReviewKeepAllTransactions;

  /// No description provided for @homeGotSomethingSellPostNow.
  ///
  /// In en, this message translates to:
  /// **'Got something to sell? Post now'**
  String get homeGotSomethingSellPostNow;

  /// No description provided for @homePublishFree30SecondsGet.
  ///
  /// In en, this message translates to:
  /// **'Publish free in 30 seconds and get buyer inquiries fast'**
  String get homePublishFree30SecondsGet;

  /// No description provided for @homePost.
  ///
  /// In en, this message translates to:
  /// **'Post +'**
  String get homePost;

  /// No description provided for @homeVerifiedOfficialStores.
  ///
  /// In en, this message translates to:
  /// **'Verified Official Stores'**
  String get homeVerifiedOfficialStores;

  /// No description provided for @homeBrowseDealsFromCertifiedStores.
  ///
  /// In en, this message translates to:
  /// **'Browse deals from certified stores and agencies'**
  String get homeBrowseDealsFromCertifiedStores;

  /// No description provided for @intentOnboardingWhatWillYouUseApolo.
  ///
  /// In en, this message translates to:
  /// **'What will you\nuse Apolo for?'**
  String get intentOnboardingWhatWillYouUseApolo;

  /// No description provided for @mainShellYouHaveNewApoloNotification.
  ///
  /// In en, this message translates to:
  /// **'You have a new Apolo notification'**
  String get mainShellYouHaveNewApoloNotification;

  /// No description provided for @mainShellBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get mainShellBrowse;

  /// No description provided for @notificationsEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnableNotifications;

  /// No description provided for @notificationsAreBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get notificationsAreBlocked;

  /// No description provided for @notificationsPleaseEnableNotificationsPhoneBrowser.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in your phone or browser settings, then tap Continue again.'**
  String get notificationsPleaseEnableNotificationsPhoneBrowser;

  /// No description provided for @notificationsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get notificationsGotIt;

  /// No description provided for @notificationsNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationsNotificationPreferences;

  /// No description provided for @notificationsChooseWhichApoloAlertsYou.
  ///
  /// In en, this message translates to:
  /// **'Choose which Apolo alerts you want to receive'**
  String get notificationsChooseWhichApoloAlertsYou;

  /// No description provided for @notificationsMessagesBuyerOffers.
  ///
  /// In en, this message translates to:
  /// **'Messages & buyer offers'**
  String get notificationsMessagesBuyerOffers;

  /// No description provided for @notificationsInstantAlertWhenBuyerMessages.
  ///
  /// In en, this message translates to:
  /// **'Instant alert when a buyer messages or makes an offer'**
  String get notificationsInstantAlertWhenBuyerMessages;

  /// No description provided for @notificationsPriceDropsSavedListings.
  ///
  /// In en, this message translates to:
  /// **'Price drops & saved listings'**
  String get notificationsPriceDropsSavedListings;

  /// No description provided for @notificationsUpdatesListingsYouBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Updates on listings you bookmarked'**
  String get notificationsUpdatesListingsYouBookmarked;

  /// No description provided for @notificationsOfficialStoresUpdates.
  ///
  /// In en, this message translates to:
  /// **'Official stores & updates'**
  String get notificationsOfficialStoresUpdates;

  /// No description provided for @notificationsNewArrivalsFromVerifiedSellers.
  ///
  /// In en, this message translates to:
  /// **'New arrivals from verified sellers you follow'**
  String get notificationsNewArrivalsFromVerifiedSellers;

  /// No description provided for @notificationsMarkAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllAsRead;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @notificationsPleaseAllowNotificationsContinue.
  ///
  /// In en, this message translates to:
  /// **'Please allow notifications to continue'**
  String get notificationsPleaseAllowNotificationsContinue;

  /// No description provided for @notificationsActivatedInstantAlerts.
  ///
  /// In en, this message translates to:
  /// **' activated instant alerts for '**
  String get notificationsActivatedInstantAlerts;

  /// No description provided for @notificationsApoloMaBuyerMessagesOffers.
  ///
  /// In en, this message translates to:
  /// **'Apolo.ma — Buyer Messages & Offers'**
  String get notificationsApoloMaBuyerMessagesOffers;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsApoloTeam.
  ///
  /// In en, this message translates to:
  /// **'Apolo Team'**
  String get notificationsApoloTeam;

  /// No description provided for @notificationsSharedTipAddClearPhotos.
  ///
  /// In en, this message translates to:
  /// **' shared a tip: Add clear photos to your listing to close deals faster.'**
  String get notificationsSharedTipAddClearPhotos;

  /// No description provided for @notifications2hAgo.
  ///
  /// In en, this message translates to:
  /// **'2h ago'**
  String get notifications2hAgo;

  /// No description provided for @notificationsApoloOfficialStores.
  ///
  /// In en, this message translates to:
  /// **'Apolo Official Stores'**
  String get notificationsApoloOfficialStores;

  /// No description provided for @notificationsUpdated.
  ///
  /// In en, this message translates to:
  /// **' updated '**
  String get notificationsUpdated;

  /// No description provided for @notificationsVerifiedCarsRealEstateTech.
  ///
  /// In en, this message translates to:
  /// **'Verified Cars, Real Estate & Tech Listings'**
  String get notificationsVerifiedCarsRealEstateTech;

  /// No description provided for @notificationsAcrossAllMoroccanCities.
  ///
  /// In en, this message translates to:
  /// **' across all Moroccan cities.'**
  String get notificationsAcrossAllMoroccanCities;

  /// No description provided for @notificationsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get notificationsThisWeek;

  /// No description provided for @notificationsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsNotifications;

  /// No description provided for @notificationsHeyItSApolo.
  ///
  /// In en, this message translates to:
  /// **'Hey, it\'s Apolo!'**
  String get notificationsHeyItSApolo;

  /// No description provided for @notificationsIAmReadyHelpYou.
  ///
  /// In en, this message translates to:
  /// **'I am ready to help you out. How about you?'**
  String get notificationsIAmReadyHelpYou;

  /// No description provided for @notificationsNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get notificationsNow;

  /// No description provided for @notificationsNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationsNotification;

  /// No description provided for @notificationsActivateNotificationsReceiveMessages.
  ///
  /// In en, this message translates to:
  /// **'Activate notifications to receive messages'**
  String get notificationsActivateNotificationsReceiveMessages;

  /// No description provided for @notificationsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notificationsUpdates;

  /// No description provided for @notificationsNoNotificationsThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this category'**
  String get notificationsNoNotificationsThisCategory;

  /// No description provided for @notificationsBuyerMessagesOffersListingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Buyer messages, offers, and listing updates will appear here.'**
  String get notificationsBuyerMessagesOffersListingUpdates;

  /// No description provided for @notificationsNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet connection'**
  String get notificationsNoInternetConnection;

  /// No description provided for @notificationsCheckWiFiMobileData.
  ///
  /// In en, this message translates to:
  /// **'Check your Wi-Fi or mobile data to refresh your notifications.'**
  String get notificationsCheckWiFiMobileData;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// No description provided for @postAdCouldNotDetectGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not detect GPS location — pick your city'**
  String get postAdCouldNotDetectGpsLocation;

  /// No description provided for @postAdPleaseSelectCategoryCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a category and city'**
  String get postAdPleaseSelectCategoryCity;

  /// No description provided for @postAdAddAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo for your listing'**
  String get postAdAddAtLeastOnePhoto;

  /// No description provided for @postAdEnterClearTitleAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear title (at least 3 characters)'**
  String get postAdEnterClearTitleAtLeast;

  /// No description provided for @postAdEnterValidPriceFreeVerify.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price or Free and verify your phone number'**
  String get postAdEnterValidPriceFreeVerify;

  /// No description provided for @postAdDailyFreeLimitReachedMaxdailyfreeads.
  ///
  /// In en, this message translates to:
  /// **'Daily free limit reached ({maxDailyFreeAds} ads/day)'**
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds);

  /// No description provided for @postAdPersonalAccountsIncludeUpMaxdailyfreeads.
  ///
  /// In en, this message translates to:
  /// **'Personal accounts include up to {maxDailyFreeAds} free ads per day. Upgrade to Apolo Premium ({monthlyPremiumPriceMad} MAD/mo via Google Pay) for unlimited daily ads, Business store, and Verified badge.'**
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad);

  /// No description provided for @postAdSubscribeMonthlypremiumpricemadMadMoGoogle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe ({monthlyPremiumPriceMad} MAD/mo) • Google Pay'**
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad);

  /// No description provided for @postAdMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get postAdMaybeLater;

  /// No description provided for @postAdPleaseSignPublishListing.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to publish your listing'**
  String get postAdPleaseSignPublishListing;

  /// No description provided for @postAdAvailableGreatConditionApolo.
  ///
  /// In en, this message translates to:
  /// **'Available in great condition on Apolo'**
  String get postAdAvailableGreatConditionApolo;

  /// No description provided for @postAdFailedPublishListing.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish your listing'**
  String get postAdFailedPublishListing;

  /// No description provided for @postAdCategoriesCitiesUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Categories and cities unavailable. Retry'**
  String get postAdCategoriesCitiesUnavailableRetry;

  /// No description provided for @postAdUnlimitedDailyAdsApoloPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlimited daily ads · Apolo Premium'**
  String get postAdUnlimitedDailyAdsApoloPremium;

  /// No description provided for @postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'{maxDailyFreeAds}/{maxDailyFreeAds2} daily limit reached · Upgrade ({monthlyPremiumPriceMad} MAD)'**
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad);

  /// No description provided for @postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds.
  ///
  /// In en, this message translates to:
  /// **'Today: {todayPostedAdsCount}/{maxDailyFreeAds} free ads · Unlimited with Premium'**
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds);

  /// No description provided for @postAdWhereAreYouListing.
  ///
  /// In en, this message translates to:
  /// **'Where are you listing?'**
  String get postAdWhereAreYouListing;

  /// No description provided for @postAdChooseCategoryCitySoNearby.
  ///
  /// In en, this message translates to:
  /// **'Choose a category and city so nearby buyers can find it easily'**
  String get postAdChooseCategoryCitySoNearby;

  /// No description provided for @postAdAddClearPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add clear photos'**
  String get postAdAddClearPhotos;

  /// No description provided for @postAdListingsRealClearPhotosSell.
  ///
  /// In en, this message translates to:
  /// **'Listings with real, clear photos sell up to 3x faster'**
  String get postAdListingsRealClearPhotosSell;

  /// No description provided for @postAdDescribeItem.
  ///
  /// In en, this message translates to:
  /// **'Describe your item'**
  String get postAdDescribeItem;

  /// No description provided for @postAdClearTitleHonestDescriptionBuild.
  ///
  /// In en, this message translates to:
  /// **'A clear title and honest description build buyer trust'**
  String get postAdClearTitleHonestDescriptionBuild;

  /// No description provided for @postAdSetPriceContact.
  ///
  /// In en, this message translates to:
  /// **'Set price and contact'**
  String get postAdSetPriceContact;

  /// No description provided for @postAdSetFairPriceReviewListing.
  ///
  /// In en, this message translates to:
  /// **'Set a fair price and review your listing before publishing'**
  String get postAdSetFairPriceReviewListing;

  /// No description provided for @postAdGpsLocationSet.
  ///
  /// In en, this message translates to:
  /// **'GPS location set'**
  String get postAdGpsLocationSet;

  /// No description provided for @postAdDetectAdLocationGps.
  ///
  /// In en, this message translates to:
  /// **'Detect ad location (GPS)'**
  String get postAdDetectAdLocationGps;

  /// No description provided for @postAdTapAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photos'**
  String get postAdTapAddPhotos;

  /// No description provided for @postAdAddMorePhotosTotalphotos8.
  ///
  /// In en, this message translates to:
  /// **'Add more photos ({totalPhotos}/8)'**
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos);

  /// No description provided for @postAdFirstPhotoWillBeUsed.
  ///
  /// In en, this message translates to:
  /// **'The first photo will be used as the main cover'**
  String get postAdFirstPhotoWillBeUsed;

  /// No description provided for @postAdGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get postAdGallery;

  /// No description provided for @postAdSelectedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Selected photos'**
  String get postAdSelectedPhotos;

  /// No description provided for @postAdCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get postAdCover;

  /// No description provided for @postAdListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get postAdListingTitle;

  /// No description provided for @postAdGreat.
  ///
  /// In en, this message translates to:
  /// **'Great ✓'**
  String get postAdGreat;

  /// No description provided for @postAdEGIphone15Pro.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 15 Pro Max 256GB like new'**
  String get postAdEGIphone15Pro;

  /// No description provided for @postAdDetailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed description'**
  String get postAdDetailedDescription;

  /// No description provided for @postAdMentionConditionIncludedAccessoriesKey.
  ///
  /// In en, this message translates to:
  /// **'Mention condition, included accessories, and key details...'**
  String get postAdMentionConditionIncludedAccessoriesKey;

  /// No description provided for @postAdSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get postAdSpecifications;

  /// No description provided for @postAdPriceMad.
  ///
  /// In en, this message translates to:
  /// **'Price (MAD)'**
  String get postAdPriceMad;

  /// No description provided for @postAdEG2500.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2500'**
  String get postAdEG2500;

  /// No description provided for @postAdHideNumber.
  ///
  /// In en, this message translates to:
  /// **'Hide number'**
  String get postAdHideNumber;

  /// No description provided for @postAdListingPreview.
  ///
  /// In en, this message translates to:
  /// **'Listing preview'**
  String get postAdListingPreview;

  /// No description provided for @postAdPublishNow.
  ///
  /// In en, this message translates to:
  /// **'Publish now'**
  String get postAdPublishNow;

  /// No description provided for @postAdListingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Listing updated'**
  String get postAdListingUpdated;

  /// No description provided for @postAdListingIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your listing is live'**
  String get postAdListingIsLive;

  /// No description provided for @postAdListingIsNowVisibleBuyers.
  ///
  /// In en, this message translates to:
  /// **'Your listing is now visible to buyers across Apolo.ma.'**
  String get postAdListingIsNowVisibleBuyers;

  /// No description provided for @postAdNewListing.
  ///
  /// In en, this message translates to:
  /// **'Your new listing'**
  String get postAdNewListing;

  /// No description provided for @postAdBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get postAdBackHome;

  /// No description provided for @postAdPostAnotherListing.
  ///
  /// In en, this message translates to:
  /// **'Post another listing'**
  String get postAdPostAnotherListing;

  /// No description provided for @privacyComplianceReportAiPolicyIssue.
  ///
  /// In en, this message translates to:
  /// **'Report AI or Policy Issue'**
  String get privacyComplianceReportAiPolicyIssue;

  /// No description provided for @privacyComplianceSelectReasonSubmitThisReport.
  ///
  /// In en, this message translates to:
  /// **'Select a reason to submit this report for immediate Trust & Safety review:'**
  String get privacyComplianceSelectReasonSubmitThisReport;

  /// No description provided for @privacyComplianceAdditionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)...'**
  String get privacyComplianceAdditionalDetailsOptional;

  /// No description provided for @privacyComplianceSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get privacyComplianceSubmitReport;

  /// No description provided for @privacyComplianceCouldNotSendReportPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not send report. Please try again.'**
  String get privacyComplianceCouldNotSendReportPlease;

  /// No description provided for @privacyComplianceReportSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully ✓'**
  String get privacyComplianceReportSubmittedSuccessfully;

  /// No description provided for @privacyComplianceLinkCopiedUrl.
  ///
  /// In en, this message translates to:
  /// **'Link copied: {url}'**
  String privacyComplianceLinkCopiedUrl(Object url);

  /// No description provided for @privacyComplianceConfirmAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm account deletion'**
  String get privacyComplianceConfirmAccountDeletion;

  /// No description provided for @privacyComplianceAreYouSureYouWant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account, personal data, listings, and messages from Apolo? This cannot be undone.'**
  String get privacyComplianceAreYouSureYouWant;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @privacyComplianceDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get privacyComplianceDeletePermanently;

  /// No description provided for @privacyComplianceAccountDataHaveBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account and data have been deleted.'**
  String get privacyComplianceAccountDataHaveBeenDeleted;

  /// No description provided for @privacyComplianceCouldNotConfirmDeletionYou.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm deletion. You remain signed in. Please try again.'**
  String get privacyComplianceCouldNotConfirmDeletionYou;

  /// No description provided for @privacyCompliancePrivacyPolicies.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policies'**
  String get privacyCompliancePrivacyPolicies;

  /// No description provided for @privacyCompliancePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyCompliancePrivacy;

  /// No description provided for @privacyCompliancePolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get privacyCompliancePolicies;

  /// No description provided for @privacyComplianceDataDelete.
  ///
  /// In en, this message translates to:
  /// **'Data & Delete'**
  String get privacyComplianceDataDelete;

  /// No description provided for @privacyComplianceUpdated2026Law0908.
  ///
  /// In en, this message translates to:
  /// **'Updated 2026 · Law 09-08 (CNDP)'**
  String get privacyComplianceUpdated2026Law0908;

  /// No description provided for @privacyCompliancePrivacyFullyControl.
  ///
  /// In en, this message translates to:
  /// **'Your privacy, fully in your control'**
  String get privacyCompliancePrivacyFullyControl;

  /// No description provided for @privacyComplianceWeNeverSellPersonalData.
  ///
  /// In en, this message translates to:
  /// **'We never sell your personal data. Information is used strictly to power your listings, secure chats, and mobile notifications on Apolo (ma.apolo.apoloMobile).'**
  String get privacyComplianceWeNeverSellPersonalData;

  /// No description provided for @privacyComplianceDataWeCollect.
  ///
  /// In en, this message translates to:
  /// **'Data We Collect'**
  String get privacyComplianceDataWeCollect;

  /// No description provided for @privacyComplianceAccountIdentityNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'• Account identity: Name, email, phone number, or secure Google / Apple sign-in.\n• Listings & stores: Photos, titles, descriptions, MAD prices, and selected city.\n• Real-time messaging: Chat messages, media, and emoji reactions between buyers and sellers.\n• Mobile push tokens (FCM / APNs): Used solely to deliver OS notifications and automatically deactivated on sign-out.'**
  String get privacyComplianceAccountIdentityNameEmailPhone;

  /// No description provided for @privacyComplianceDevicePermissionsControls.
  ///
  /// In en, this message translates to:
  /// **'Device Permissions & Controls'**
  String get privacyComplianceDevicePermissionsControls;

  /// No description provided for @privacyComplianceNotificationsOptionalOsAlertsNew.
  ///
  /// In en, this message translates to:
  /// **'• Notifications: Optional OS alerts for new messages on iOS & Android; adjustable anytime.\n• Camera & Photos: Requested only when you upload listing photos or chat attachments.\n• Approximate zone: City-level distance filtering with zero background GPS tracking.'**
  String get privacyComplianceNotificationsOptionalOsAlertsNew;

  /// No description provided for @privacyComplianceAiSafetyAppReporting.
  ///
  /// In en, this message translates to:
  /// **'AI Safety & In-App Reporting'**
  String get privacyComplianceAiSafetyAppReporting;

  /// No description provided for @privacyComplianceSmartListingSearchToolsInclude.
  ///
  /// In en, this message translates to:
  /// **'Smart listing and search tools include direct in-app reporting so you can flag inaccurate AI suggestions or abusive listings immediately.'**
  String get privacyComplianceSmartListingSearchToolsInclude;

  /// No description provided for @privacyComplianceLegalRightsContact.
  ///
  /// In en, this message translates to:
  /// **'Your Legal Rights & Contact'**
  String get privacyComplianceLegalRightsContact;

  /// No description provided for @privacyComplianceUnderMoroccanLaw0908.
  ///
  /// In en, this message translates to:
  /// **'Under Moroccan Law 09-08 and App Store / Google Play rules, you have the right to access, update, or permanently erase your personal data.\n• Official email: support@apolo.ma / contact@apolo.ma\n• Website: https://apolo.ma'**
  String get privacyComplianceUnderMoroccanLaw0908;

  /// No description provided for @privacyComplianceReportAiPolicyIssueApp.
  ///
  /// In en, this message translates to:
  /// **'Report AI or Policy Issue In-App'**
  String get privacyComplianceReportAiPolicyIssueApp;

  /// No description provided for @privacyComplianceOpenWebPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Open Web Privacy Policy'**
  String get privacyComplianceOpenWebPrivacyPolicy;

  /// No description provided for @privacyComplianceTermsUseMarketplaceRules.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use & Marketplace Rules'**
  String get privacyComplianceTermsUseMarketplaceRules;

  /// No description provided for @privacyComplianceClearRulesSafeBuyingSelling.
  ///
  /// In en, this message translates to:
  /// **'Clear rules for safe buying & selling'**
  String get privacyComplianceClearRulesSafeBuyingSelling;

  /// No description provided for @privacyComplianceByUsingApoloYouAgree.
  ///
  /// In en, this message translates to:
  /// **'By using Apolo, you agree to authentic listings, respectful messaging, and transparent marketplace rules.'**
  String get privacyComplianceByUsingApoloYouAgree;

  /// No description provided for @privacyComplianceAccountIntegrityVerifiedBadges.
  ///
  /// In en, this message translates to:
  /// **'Account Integrity & Verified Badges'**
  String get privacyComplianceAccountIntegrityVerifiedBadges;

  /// No description provided for @privacyComplianceAccountStoreDetailsMustRemain.
  ///
  /// In en, this message translates to:
  /// **'• Account and store details must remain accurate and truthful.\n• Verified seals and seller ranks (Bronze to Champion) are awarded strictly by Apolo; impersonation is prohibited.'**
  String get privacyComplianceAccountStoreDetailsMustRemain;

  /// No description provided for @privacyComplianceListingRulesProhibitedItems.
  ///
  /// In en, this message translates to:
  /// **'Listing Rules & Prohibited Items'**
  String get privacyComplianceListingRulesProhibitedItems;

  /// No description provided for @privacyComplianceListingsMustRepresentRealItems.
  ///
  /// In en, this message translates to:
  /// **'• Listings must represent real items or services with genuine photos and honest pricing.\n• Strictly prohibited: counterfeit goods, weapons, illegal substances, prescription drugs, stolen goods, and advance-fee scams.'**
  String get privacyComplianceListingsMustRepresentRealItems;

  /// No description provided for @privacyComplianceSafeTransactionsChatConduct.
  ///
  /// In en, this message translates to:
  /// **'Safe Transactions & Chat Conduct'**
  String get privacyComplianceSafeTransactionsChatConduct;

  /// No description provided for @privacyComplianceAlwaysInspectItemsPersonSafe.
  ///
  /// In en, this message translates to:
  /// **'• Always inspect items in person in a safe public place and avoid sending advance deposits.\n• Spam, harassment, and abusive messages result in immediate suspension; block or report anytime.'**
  String get privacyComplianceAlwaysInspectItemsPersonSafe;

  /// No description provided for @privacyComplianceProSubscriptionsListingBoosts.
  ///
  /// In en, this message translates to:
  /// **'Pro+ Subscriptions & Listing Boosts'**
  String get privacyComplianceProSubscriptionsListingBoosts;

  /// No description provided for @privacyComplianceProPlansBoostUpgradesAre.
  ///
  /// In en, this message translates to:
  /// **'• Pro+ plans and Boost upgrades are billed transparently through your App Store or Google Play account.\n• Cancel auto-renewal anytime at least 24 hours before period end in your store account settings.'**
  String get privacyComplianceProPlansBoostUpgradesAre;

  /// No description provided for @privacyComplianceOpenWebTermsPolicies.
  ///
  /// In en, this message translates to:
  /// **'Open Web Terms & Policies'**
  String get privacyComplianceOpenWebTermsPolicies;

  /// No description provided for @privacyComplianceInstantErasureAppStorePlay.
  ///
  /// In en, this message translates to:
  /// **'Instant Erasure · App Store & Play'**
  String get privacyComplianceInstantErasureAppStorePlay;

  /// No description provided for @privacyCompliancePermanentAccountDataDeletion.
  ///
  /// In en, this message translates to:
  /// **'Permanent Account & Data Deletion'**
  String get privacyCompliancePermanentAccountDataDeletion;

  /// No description provided for @privacyComplianceEraseAccountAllAssociatedPersonal.
  ///
  /// In en, this message translates to:
  /// **'Erase your account and all associated personal data directly in-app or via our external web deletion form.'**
  String get privacyComplianceEraseAccountAllAssociatedPersonal;

  /// No description provided for @privacyComplianceWhatGetsPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'What Gets Permanently Deleted'**
  String get privacyComplianceWhatGetsPermanentlyDeleted;

  /// No description provided for @privacyComplianceProfileCredentialsNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'• Profile credentials (name, email, phone number, and OAuth links).\n• All published listings, uploaded photos, and store data.\n• Chat history, saved favorites, and active mobile push notification tokens.'**
  String get privacyComplianceProfileCredentialsNameEmailPhone;

  /// No description provided for @privacyComplianceDeleteMyAccountNowApp.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account Now (In-App)'**
  String get privacyComplianceDeleteMyAccountNowApp;

  /// No description provided for @privacyComplianceSignDeleteAccountDirectlyApp.
  ///
  /// In en, this message translates to:
  /// **'Sign in to delete your account directly in-app, or use the external web link below.'**
  String get privacyComplianceSignDeleteAccountDirectlyApp;

  /// No description provided for @privacyComplianceExternalWebDataDeletionLink.
  ///
  /// In en, this message translates to:
  /// **'External Web Data Deletion Link'**
  String get privacyComplianceExternalWebDataDeletionLink;

  /// No description provided for @proPlusRecurringBillingCancelAnytimePayment.
  ///
  /// In en, this message translates to:
  /// **'Recurring billing. Cancel anytime. Payment will be charged to your Google Pay / Store account at confirmation of purchase and automatically renews unless turned off at least 24 hours before the end of the current period.\nAll personal data is handled under the '**
  String get proPlusRecurringBillingCancelAnytimePayment;

  /// No description provided for @proPlusTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get proPlusTermsConditions;

  /// No description provided for @proPlusAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get proPlusAnd;

  /// No description provided for @proPlusPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get proPlusPrivacyPolicy;

  /// No description provided for @proPlusSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get proPlusSubscription;

  /// No description provided for @proPlusCancelPremiumSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel your Premium subscription?'**
  String get proPlusCancelPremiumSubscription;

  /// No description provided for @proPlusAutoRenewalWillBeTurned.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal will be turned off while keeping your store and listings safe.'**
  String get proPlusAutoRenewalWillBeTurned;

  /// No description provided for @proPlusCancelMySubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel my subscription'**
  String get proPlusCancelMySubscription;

  /// No description provided for @proPlusKeepPremium.
  ///
  /// In en, this message translates to:
  /// **'Keep Premium'**
  String get proPlusKeepPremium;

  /// No description provided for @proPlusYouUsePremium.
  ///
  /// In en, this message translates to:
  /// **'You use Premium'**
  String get proPlusYouUsePremium;

  /// No description provided for @proPlusGetPremium.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get proPlusGetPremium;

  /// No description provided for @proPlusYouHaveUnlimitedAccessAll.
  ///
  /// In en, this message translates to:
  /// **'You have unlimited access to all premium features'**
  String get proPlusYouHaveUnlimitedAccessAll;

  /// No description provided for @proPlusGetUnlimitedAccessAllPremium.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited access to all premium features'**
  String get proPlusGetUnlimitedAccessAllPremium;

  /// No description provided for @proPlusCheckedAccountActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'Checked your account for active purchases.'**
  String get proPlusCheckedAccountActivePurchases;

  /// No description provided for @proPlusHowTrialWorks.
  ///
  /// In en, this message translates to:
  /// **'How your trial works'**
  String get proPlusHowTrialWorks;

  /// No description provided for @proPlusUnlimitedFreeAccess3Days.
  ///
  /// In en, this message translates to:
  /// **'Unlimited free access for 3 days, then only {monthlyPremiumPriceMad} MAD/month via Google Pay'**
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad);

  /// No description provided for @proPlusGetInstantAccessSeeHow.
  ///
  /// In en, this message translates to:
  /// **'Get instant access and see how Pro Plus transforms your sales.'**
  String get proPlusGetInstantAccessSeeHow;

  /// No description provided for @proPlusDay2.
  ///
  /// In en, this message translates to:
  /// **'Day 2'**
  String get proPlusDay2;

  /// No description provided for @proPlusWeLlRemindYouNotification.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you with a notification that your trial is ending.'**
  String get proPlusWeLlRemindYouNotification;

  /// No description provided for @proPlusDay3.
  ///
  /// In en, this message translates to:
  /// **'Day 3'**
  String get proPlusDay3;

  /// No description provided for @proPlusYouLlBeChargedDay.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be charged on Day 3, cancel anytime before.'**
  String get proPlusYouLlBeChargedDay;

  /// No description provided for @proPlusViewAllPlans.
  ///
  /// In en, this message translates to:
  /// **'View all plans'**
  String get proPlusViewAllPlans;

  /// No description provided for @proPlusRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get proPlusRestorePurchases;

  /// No description provided for @proPlusStartFree3DayTrial.
  ///
  /// In en, this message translates to:
  /// **'Start free 3-day trial'**
  String get proPlusStartFree3DayTrial;

  /// No description provided for @proPlusPaymentVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment verification failed.'**
  String get proPlusPaymentVerificationFailed;

  /// No description provided for @proPlusProPlusActivatedStoreIs.
  ///
  /// In en, this message translates to:
  /// **'Pro Plus activated! Your store is now verified'**
  String get proPlusProPlusActivatedStoreIs;

  /// No description provided for @proPlusCouldNotLaunchGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Could not launch Google Pay on this device.'**
  String get proPlusCouldNotLaunchGooglePay;

  /// No description provided for @proPlusPayGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Pay with Google Pay'**
  String get proPlusPayGooglePay;

  /// No description provided for @proPlusSave25.
  ///
  /// In en, this message translates to:
  /// **'Save 25%'**
  String get proPlusSave25;

  /// No description provided for @proPlusLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get proPlusLifetime;

  /// No description provided for @proPlusBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get proPlusBasic;

  /// No description provided for @proPlus12Months.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get proPlus12Months;

  /// No description provided for @proPlusOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get proPlusOneTime;

  /// No description provided for @proPlus1Month.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get proPlus1Month;

  /// No description provided for @proPlusMad.
  ///
  /// In en, this message translates to:
  /// **'MAD'**
  String get proPlusMad;

  /// No description provided for @proPlusPaywall.
  ///
  /// In en, this message translates to:
  /// **'Paywall'**
  String get proPlusPaywall;

  /// No description provided for @proPlusUnlockFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access'**
  String get proPlusUnlockFullAccess;

  /// No description provided for @proPlusUnlimitedAccessAllFeaturesTemplates.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access to all features and templates'**
  String get proPlusUnlimitedAccessAllFeaturesTemplates;

  /// No description provided for @proPlusOfficialBusinessStoreBlueVerified.
  ///
  /// In en, this message translates to:
  /// **'Official Business store + blue Verified badge'**
  String get proPlusOfficialBusinessStoreBlueVerified;

  /// No description provided for @proPlusUnlimitedDailyListingsInstead5.
  ///
  /// In en, this message translates to:
  /// **'Unlimited daily listings (instead of 5/day) + 12 photos'**
  String get proPlusUnlimitedDailyListingsInstead5;

  /// No description provided for @proPlus5FreeMonthlyVipBoosts.
  ///
  /// In en, this message translates to:
  /// **'5 free monthly VIP boosts + Pro Insights & quick replies'**
  String get proPlus5FreeMonthlyVipBoosts;

  /// No description provided for @proPlusSubscribePricedisplayMadGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {priceDisplay} MAD • Google Pay'**
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay);

  /// No description provided for @proPlusNoThankYou.
  ///
  /// In en, this message translates to:
  /// **'No, thank you'**
  String get proPlusNoThankYou;

  /// No description provided for @profileCouldNotLoadListingsPull.
  ///
  /// In en, this message translates to:
  /// **'Could not load listings. Pull to retry.'**
  String get profileCouldNotLoadListingsPull;

  /// No description provided for @profileMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get profileMyAccount;

  /// No description provided for @profileSettingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Settings & support'**
  String get profileSettingsSupport;

  /// No description provided for @profileSignManageListingsSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your listings, saved items, and instant chats.'**
  String get profileSignManageListingsSavedItems;

  /// No description provided for @profileSignViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your profile'**
  String get profileSignViewProfile;

  /// No description provided for @welcomeCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccountButton;

  /// No description provided for @profileLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get profileLightMode;

  /// No description provided for @profileDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get profileDarkMode;

  /// No description provided for @profileListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileListings;

  /// No description provided for @profileLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get profileLikes;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @shareProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfileButton;

  /// No description provided for @profileMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get profileMyListings;

  /// No description provided for @profileProInsightsBoost.
  ///
  /// In en, this message translates to:
  /// **'Pro Insights & Boost'**
  String get profileProInsightsBoost;

  /// No description provided for @profileUpgradeApoloPremiumMonthlypremiumpricemadMad.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Apolo Premium · {monthlyPremiumPriceMad} MAD/mo'**
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad);

  /// No description provided for @profileBusinessStoreVerifiedBadgeUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Business store + Verified badge + unlimited daily ads via Google Pay.'**
  String get profileBusinessStoreVerifiedBadgeUnlimited;

  /// No description provided for @profileViewStore.
  ///
  /// In en, this message translates to:
  /// **'View store'**
  String get profileViewStore;

  /// No description provided for @profileEditStore.
  ///
  /// In en, this message translates to:
  /// **'Edit store'**
  String get profileEditStore;

  /// No description provided for @profileQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get profileQuickReplies;

  /// No description provided for @profileNoListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get profileNoListingsYet;

  /// No description provided for @profilePublishFirstListingShowcaseIt.
  ///
  /// In en, this message translates to:
  /// **'Publish your first listing to showcase it here.'**
  String get profilePublishFirstListingShowcaseIt;

  /// No description provided for @profilePostListing.
  ///
  /// In en, this message translates to:
  /// **'Post a listing'**
  String get profilePostListing;

  /// No description provided for @profileTotalViews.
  ///
  /// In en, this message translates to:
  /// **'Total views'**
  String get profileTotalViews;

  /// No description provided for @profileActiveListings.
  ///
  /// In en, this message translates to:
  /// **'Active listings'**
  String get profileActiveListings;

  /// No description provided for @profileAvgListing.
  ///
  /// In en, this message translates to:
  /// **'Avg. / listing'**
  String get profileAvgListing;

  /// No description provided for @profileBoostedListings.
  ///
  /// In en, this message translates to:
  /// **'Boosted listings'**
  String get profileBoostedListings;

  /// No description provided for @profileCallTaps.
  ///
  /// In en, this message translates to:
  /// **'Call taps'**
  String get profileCallTaps;

  /// No description provided for @profileCustomerChats.
  ///
  /// In en, this message translates to:
  /// **'Customer chats'**
  String get profileCustomerChats;

  /// No description provided for @profileDirectOrders.
  ///
  /// In en, this message translates to:
  /// **'Direct orders'**
  String get profileDirectOrders;

  /// No description provided for @profileFreeVipCredits.
  ///
  /// In en, this message translates to:
  /// **'Free VIP credits'**
  String get profileFreeVipCredits;

  /// No description provided for @profileUnlockCallOrderStatsPro.
  ///
  /// In en, this message translates to:
  /// **'Unlock call & order stats + PRO+ Badge'**
  String get profileUnlockCallOrderStatsPro;

  /// No description provided for @profileGet3FreeVipBoosts.
  ///
  /// In en, this message translates to:
  /// **'Get 3 free VIP boosts/month and priority visibility.'**
  String get profileGet3FreeVipBoosts;

  /// No description provided for @profileViewsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Views breakdown'**
  String get profileViewsBreakdown;

  /// No description provided for @profileLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get profileLive;

  /// No description provided for @profilePublishFirstListingTrackViews.
  ///
  /// In en, this message translates to:
  /// **'Publish your first listing to track views and performance here.'**
  String get profilePublishFirstListingTrackViews;

  /// No description provided for @profileTopPerformingListings.
  ///
  /// In en, this message translates to:
  /// **'Top performing listings'**
  String get profileTopPerformingListings;

  /// No description provided for @profileViews.
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get profileViews;

  /// No description provided for @profileSalesTip.
  ///
  /// In en, this message translates to:
  /// **'Sales tip'**
  String get profileSalesTip;

  /// No description provided for @profileAddClearPhotosFairPrice.
  ///
  /// In en, this message translates to:
  /// **'Add clear photos and a fair price on your first listing to attract buyers fast.'**
  String get profileAddClearPhotosFairPrice;

  /// No description provided for @profileRefreshingPhotosBoostingTopListing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing photos or boosting your top listing helps it sell faster.'**
  String get profileRefreshingPhotosBoostingTopListing;

  /// No description provided for @profileEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get profileEditListing;

  /// No description provided for @profileBoostThisListing.
  ///
  /// In en, this message translates to:
  /// **'Boost this listing'**
  String get profileBoostThisListing;

  /// No description provided for @profileDeleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get profileDeleteListing;

  /// No description provided for @profileCouldNotDeleteListingPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not delete listing. Please try again.'**
  String get profileCouldNotDeleteListingPlease;

  /// No description provided for @profileDeleteThisListing.
  ///
  /// In en, this message translates to:
  /// **'Delete this listing?'**
  String get profileDeleteThisListing;

  /// No description provided for @profileThisListingWillBePermanently.
  ///
  /// In en, this message translates to:
  /// **'This listing will be permanently removed from your profile and search results.'**
  String get profileThisListingWillBePermanently;

  /// No description provided for @profileListingDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted successfully'**
  String get profileListingDeletedSuccessfully;

  /// No description provided for @scanProfileCodeThisIsOwnProfile.
  ///
  /// In en, this message translates to:
  /// **'This is your own profile'**
  String get scanProfileCodeThisIsOwnProfile;

  /// No description provided for @scanProfileCodeApoloMemberSellerid.
  ///
  /// In en, this message translates to:
  /// **'Apolo Member #{sellerId}'**
  String scanProfileCodeApoloMemberSellerid(Object sellerId);

  /// No description provided for @scanProfileCodeScannedCode.
  ///
  /// In en, this message translates to:
  /// **'Scanned Code'**
  String get scanProfileCodeScannedCode;

  /// No description provided for @scanProfileCodeCodeDetected.
  ///
  /// In en, this message translates to:
  /// **'Code Detected'**
  String get scanProfileCodeCodeDetected;

  /// No description provided for @scanProfileCodeOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get scanProfileCodeOpenLink;

  /// No description provided for @scanProfileCodeScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanProfileCodeScanAgain;

  /// No description provided for @scanProfileCodeFlashlightIsUnavailableThisBrowser.
  ///
  /// In en, this message translates to:
  /// **'Flashlight is unavailable in this browser'**
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser;

  /// No description provided for @scanProfileCodeFlashlightIsUnavailableThisCamera.
  ///
  /// In en, this message translates to:
  /// **'Flashlight is unavailable on this camera'**
  String get scanProfileCodeFlashlightIsUnavailableThisCamera;

  /// No description provided for @scanProfileCodeCouldNotToggleFlashlightRight.
  ///
  /// In en, this message translates to:
  /// **'Could not toggle flashlight right now'**
  String get scanProfileCodeCouldNotToggleFlashlightRight;

  /// No description provided for @scanProfileCodeNoQrCodeDetectedSelected.
  ///
  /// In en, this message translates to:
  /// **'No QR code detected in the selected image'**
  String get scanProfileCodeNoQrCodeDetectedSelected;

  /// No description provided for @scanProfileCodeEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get scanProfileCodeEnterCode;

  /// No description provided for @scanProfileCodeCouldNotOpenPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Could not open photo library'**
  String get scanProfileCodeCouldNotOpenPhotoLibrary;

  /// No description provided for @scanProfileCodeScanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanProfileCodeScanQrCode;

  /// No description provided for @scanProfileCodePickQrImage.
  ///
  /// In en, this message translates to:
  /// **'Pick QR image'**
  String get scanProfileCodePickQrImage;

  /// No description provided for @scanProfileCodeTapEnableCamera.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable camera'**
  String get scanProfileCodeTapEnableCamera;

  /// No description provided for @scanProfileCodeEnterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get scanProfileCodeEnterCodeManually;

  /// No description provided for @scanProfileCodePleaseEnterLinkHandle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a link or handle'**
  String get scanProfileCodePleaseEnterLinkHandle;

  /// No description provided for @scanProfileCodePasteApoloProfileLinkEnter.
  ///
  /// In en, this message translates to:
  /// **'Paste an Apolo profile link or enter @handle'**
  String get scanProfileCodePasteApoloProfileLinkEnter;

  /// No description provided for @scanProfileCodeOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get scanProfileCodeOpenProfile;

  /// No description provided for @searchRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get searchRecommended;

  /// No description provided for @searchNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get searchNewest;

  /// No description provided for @searchLowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get searchLowestPrice;

  /// No description provided for @searchHighestPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get searchHighestPrice;

  /// No description provided for @searchMostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most viewed'**
  String get searchMostViewed;

  /// No description provided for @searchFilterSort.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get searchFilterSort;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @searchSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchSortBy;

  /// No description provided for @searchAllMorocco.
  ///
  /// In en, this message translates to:
  /// **'All Morocco'**
  String get searchAllMorocco;

  /// No description provided for @searchPriceRangeMad.
  ///
  /// In en, this message translates to:
  /// **'Price range (MAD)'**
  String get searchPriceRangeMad;

  /// No description provided for @searchMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get searchMinPrice;

  /// No description provided for @searchMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get searchMaxPrice;

  /// No description provided for @searchNegotiableListingsOnly.
  ///
  /// In en, this message translates to:
  /// **'Negotiable listings only'**
  String get searchNegotiableListingsOnly;

  /// No description provided for @searchApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get searchApplyFilters;

  /// No description provided for @searchSignSaveSearchesListings.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save searches & listings'**
  String get searchSignSaveSearchesListings;

  /// No description provided for @searchSaved.
  ///
  /// In en, this message translates to:
  /// **'Search saved'**
  String get searchSaved;

  /// No description provided for @searchUnableSaveSearchRightNow.
  ///
  /// In en, this message translates to:
  /// **'Unable to save search right now'**
  String get searchUnableSaveSearchRightNow;

  /// No description provided for @searchSaveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save search'**
  String get searchSaveSearch;

  /// No description provided for @searchNoSavedListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved listings yet'**
  String get searchNoSavedListingsYet;

  /// No description provided for @searchTapHeartAnyListingSave.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any listing to save it here'**
  String get searchTapHeartAnyListingSave;

  /// No description provided for @searchFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get searchFilter;

  /// No description provided for @searchAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get searchAllCategories;

  /// No description provided for @searchAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get searchAllAreas;

  /// No description provided for @searchSetArea.
  ///
  /// In en, this message translates to:
  /// **'Set area'**
  String get searchSetArea;

  /// No description provided for @searchFeedView.
  ///
  /// In en, this message translates to:
  /// **'Feed view'**
  String get searchFeedView;

  /// No description provided for @searchGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get searchGridView;

  /// No description provided for @personalAccountBadge.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalAccountBadge;

  /// No description provided for @businessAccountBadge.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessAccountBadge;

  /// No description provided for @searchNoListingsWithinZoneradiuskmKm.
  ///
  /// In en, this message translates to:
  /// **'No listings within {zoneRadiusKm} km of {s}.'**
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s);

  /// No description provided for @searchTryAnotherCategoryBroadenFilters.
  ///
  /// In en, this message translates to:
  /// **'Try another category or broaden your filters.'**
  String get searchTryAnotherCategoryBroadenFilters;

  /// No description provided for @searchResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get searchResetFilters;

  /// No description provided for @sellerProfileSellerPhoneNumberNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Seller phone number not available'**
  String get sellerProfileSellerPhoneNumberNotAvailable;

  /// No description provided for @sellerProfileSelectListingMessageThisSeller.
  ///
  /// In en, this message translates to:
  /// **'Select a listing to message this seller.'**
  String get sellerProfileSelectListingMessageThisSeller;

  /// No description provided for @sellerProfileReportSeller.
  ///
  /// In en, this message translates to:
  /// **'Report seller'**
  String get sellerProfileReportSeller;

  /// No description provided for @sellerProfileBlockSeller.
  ///
  /// In en, this message translates to:
  /// **'Block seller'**
  String get sellerProfileBlockSeller;

  /// No description provided for @sellerProfileSellerBlockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Seller blocked successfully'**
  String get sellerProfileSellerBlockedSuccessfully;

  /// No description provided for @sellerProfileFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get sellerProfileFollowers;

  /// No description provided for @sellerProfileRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sellerProfileRating;

  /// No description provided for @sellerProfileStorecategorylabelCityStorehours.
  ///
  /// In en, this message translates to:
  /// **'{storeCategoryLabel} · {city} · {storeHours}'**
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours);

  /// No description provided for @sellerProfileIndividualSellerCityDirectChat.
  ///
  /// In en, this message translates to:
  /// **'Individual seller in {city} · Direct chat reply.'**
  String sellerProfileIndividualSellerCityDirectChat(Object city);

  /// No description provided for @sellerProfileVisitStore.
  ///
  /// In en, this message translates to:
  /// **'Visit store'**
  String get sellerProfileVisitStore;

  /// No description provided for @sellerProfileListingsSellerads.
  ///
  /// In en, this message translates to:
  /// **'Listings ({sellerAds})'**
  String sellerProfileListingsSellerads(Object sellerAds);

  /// No description provided for @sellerProfileReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String sellerProfileReviewsCount(Object count);

  /// No description provided for @sellerProfileTrustInfo.
  ///
  /// In en, this message translates to:
  /// **'Trust & Info'**
  String get sellerProfileTrustInfo;

  /// No description provided for @sellerProfileNoListingsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No listings available right now'**
  String get sellerProfileNoListingsAvailableRightNow;

  /// No description provided for @sellerProfile3DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'3 days ago'**
  String get sellerProfile3DaysAgo;

  /// No description provided for @sellerProfileVeryReliableSellerItemMatched.
  ///
  /// In en, this message translates to:
  /// **'Very reliable seller, item matched the photos and great communication throughout.'**
  String get sellerProfileVeryReliableSellerItemMatched;

  /// No description provided for @sellerProfile1WeekAgo.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get sellerProfile1WeekAgo;

  /// No description provided for @sellerProfileSmoothBuyingExperienceInspectedBefore.
  ///
  /// In en, this message translates to:
  /// **'Smooth buying experience, inspected before payment. Highly recommended!'**
  String get sellerProfileSmoothBuyingExperienceInspectedBefore;

  /// No description provided for @sellerProfile2WeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'2 weeks ago'**
  String get sellerProfile2WeeksAgo;

  /// No description provided for @sellerProfileHonestRespectfulSellerLetMe.
  ///
  /// In en, this message translates to:
  /// **'Honest and respectful seller. Let me inspect the laptop thoroughly.'**
  String get sellerProfileHonestRespectfulSellerLetMe;

  /// No description provided for @sellerProfile1MonthAgo.
  ///
  /// In en, this message translates to:
  /// **'1 month ago'**
  String get sellerProfile1MonthAgo;

  /// No description provided for @sellerProfileGreatTransactionFullTrustFast.
  ///
  /// In en, this message translates to:
  /// **'Great transaction with full trust. Fast replies on Apolo chat.'**
  String get sellerProfileGreatTransactionFullTrustFast;

  /// No description provided for @sellerProfileCountVerifiedReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} verified reviews'**
  String sellerProfileCountVerifiedReviews(Object count);

  /// No description provided for @sellerProfileGovernmentIdVerified.
  ///
  /// In en, this message translates to:
  /// **'Government ID Verified'**
  String get sellerProfileGovernmentIdVerified;

  /// No description provided for @sellerProfileOfficialIdentityDocumentReviewedVerified.
  ///
  /// In en, this message translates to:
  /// **'Official identity document reviewed and verified by Apolo Trust Team.'**
  String get sellerProfileOfficialIdentityDocumentReviewedVerified;

  /// No description provided for @sellerProfileVerifiedPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verified Phone Number'**
  String get sellerProfileVerifiedPhoneNumber;

  /// No description provided for @sellerProfilePhoneNumberConfirmedViaSms.
  ///
  /// In en, this message translates to:
  /// **'Phone number confirmed via SMS OTP verification.'**
  String get sellerProfilePhoneNumberConfirmedViaSms;

  /// No description provided for @sellerProfileApoloSafetyProtection.
  ///
  /// In en, this message translates to:
  /// **'Apolo Safety Protection'**
  String get sellerProfileApoloSafetyProtection;

  /// No description provided for @sellerProfileWeRecommendInspectingItemPerson.
  ///
  /// In en, this message translates to:
  /// **'We recommend inspecting the item in person before making any payment.'**
  String get sellerProfileWeRecommendInspectingItemPerson;

  /// No description provided for @sellerProfileAvailableDeliveryMethods.
  ///
  /// In en, this message translates to:
  /// **'Available Delivery Methods'**
  String get sellerProfileAvailableDeliveryMethods;

  /// No description provided for @sellerProfileHandHandPickupCityInsured.
  ///
  /// In en, this message translates to:
  /// **'Hand-to-hand pickup in {city}, or insured express shipping by agreement.'**
  String sellerProfileHandHandPickupCityInsured(Object city);

  /// No description provided for @accountCenterSwitchPersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch to Personal Account'**
  String get accountCenterSwitchPersonalAccount;

  /// No description provided for @accountCenterReturnPersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Return to a personal account?'**
  String get accountCenterReturnPersonalAccount;

  /// No description provided for @accountCenterBusinessStorePageWillBe.
  ///
  /// In en, this message translates to:
  /// **'Your business store page will be paused. You can re-enable it anytime.'**
  String get accountCenterBusinessStorePageWillBe;

  /// No description provided for @accountCenterConfirmSwitch.
  ///
  /// In en, this message translates to:
  /// **'Confirm switch'**
  String get accountCenterConfirmSwitch;

  /// No description provided for @accountCenterSwitchedPersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Switched to Personal Account.'**
  String get accountCenterSwitchedPersonalAccount;

  /// No description provided for @accountCenterCouldNotSwitchAccountType.
  ///
  /// In en, this message translates to:
  /// **'Could not switch account type. Please try again.'**
  String get accountCenterCouldNotSwitchAccountType;

  /// No description provided for @accountCenterApoloAccount.
  ///
  /// In en, this message translates to:
  /// **'Apolo Account'**
  String get accountCenterApoloAccount;

  /// No description provided for @accountCenterPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get accountCenterPersonalDetails;

  /// No description provided for @accountCenterEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Email & phone'**
  String get accountCenterEmailPhone;

  /// No description provided for @accountCenterAccountTypePreferences.
  ///
  /// In en, this message translates to:
  /// **'Account type & preferences'**
  String get accountCenterAccountTypePreferences;

  /// No description provided for @accountCenterPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password & security'**
  String get accountCenterPasswordSecurity;

  /// No description provided for @accountCenterResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get accountCenterResetPassword;

  /// No description provided for @accountCenterBusinessStore.
  ///
  /// In en, this message translates to:
  /// **'Business & Store'**
  String get accountCenterBusinessStore;

  /// No description provided for @accountCenterEditStoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Store Profile'**
  String get accountCenterEditStoreProfile;

  /// No description provided for @accountCenterSwitchBusinessAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch to Business Account'**
  String get accountCenterSwitchBusinessAccount;

  /// No description provided for @accountCenterAccountOwnership.
  ///
  /// In en, this message translates to:
  /// **'Account ownership'**
  String get accountCenterAccountOwnership;

  /// No description provided for @accountCenterDeleteAccountData.
  ///
  /// In en, this message translates to:
  /// **'Delete account & data'**
  String get accountCenterDeleteAccountData;

  /// No description provided for @accountCenterManageApoloAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your Apolo Account'**
  String get accountCenterManageApoloAccount;

  /// No description provided for @accountCenterSignManageSecurityPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage security, personal details, and your store.'**
  String get accountCenterSignManageSecurityPersonalDetails;

  /// No description provided for @logInButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInButton;

  /// No description provided for @settingsAppDataAppDataRefreshedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'App data refreshed successfully.'**
  String get settingsAppDataAppDataRefreshedSuccessfully;

  /// No description provided for @settingsAppDataCouldNotRefreshDataCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh data. Check your connection and try again.'**
  String get settingsAppDataCouldNotRefreshDataCheck;

  /// No description provided for @settingsAppDataAppDataSync.
  ///
  /// In en, this message translates to:
  /// **'App data & sync'**
  String get settingsAppDataAppDataSync;

  /// No description provided for @settingsAppDataSystemInformationLocalSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'System information and local sync status with Apolo.ma.'**
  String get settingsAppDataSystemInformationLocalSyncStatus;

  /// No description provided for @settingsAppDataApplicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Application status'**
  String get settingsAppDataApplicationStatus;

  /// No description provided for @settingsAppDataAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppDataAppVersion;

  /// No description provided for @settingsAppDataServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsAppDataServer;

  /// No description provided for @settingsAppDataSyncedCategories.
  ///
  /// In en, this message translates to:
  /// **'Synced categories'**
  String get settingsAppDataSyncedCategories;

  /// No description provided for @settingsAppDataSyncedCities.
  ///
  /// In en, this message translates to:
  /// **'Synced cities'**
  String get settingsAppDataSyncedCities;

  /// No description provided for @settingsAppDataActiveZone.
  ///
  /// In en, this message translates to:
  /// **'Active zone'**
  String get settingsAppDataActiveZone;

  /// No description provided for @settingsAppDataOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsAppDataOpenSourceLicenses;

  /// No description provided for @settingsAppDataRefreshDataNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh data now'**
  String get settingsAppDataRefreshDataNow;

  /// No description provided for @settingsAppearanceAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceAppearance;

  /// No description provided for @settingsAppearanceChooseHowApoloLooksSwitch.
  ///
  /// In en, this message translates to:
  /// **'Choose how Apolo looks. Switch between Light mode, Dark mode, or match your device settings automatically.'**
  String get settingsAppearanceChooseHowApoloLooksSwitch;

  /// No description provided for @settingsAppearanceCleanWhiteSurfacesCrispDaylight.
  ///
  /// In en, this message translates to:
  /// **'Clean white surfaces and crisp daylight contrast'**
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight;

  /// No description provided for @settingsAppearanceEasyEyesLowLightSaves.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes in low light and saves battery'**
  String get settingsAppearanceEasyEyesLowLightSaves;

  /// No description provided for @settingsAppearanceSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsAppearanceSystemDefault;

  /// No description provided for @settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme.
  ///
  /// In en, this message translates to:
  /// **'Automatically matches your phone or browser theme'**
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme;

  /// No description provided for @settingsBlockedAccountsUnblockedName.
  ///
  /// In en, this message translates to:
  /// **'Unblocked {name}'**
  String settingsBlockedAccountsUnblockedName(Object name);

  /// No description provided for @settingsBlockedAccountsBlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked accounts'**
  String get settingsBlockedAccountsBlockedAccounts;

  /// No description provided for @settingsBlockedAccountsNoBlockedAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No blocked accounts yet'**
  String get settingsBlockedAccountsNoBlockedAccountsYet;

  /// No description provided for @settingsBlockedAccountsUsersStoresYouBlockFrom.
  ///
  /// In en, this message translates to:
  /// **'Users or stores you block from chats or listings will appear here so you can unblock them anytime.'**
  String get settingsBlockedAccountsUsersStoresYouBlockFrom;

  /// No description provided for @settingsBlockedAccountsYouCanUnblockAnyUser.
  ///
  /// In en, this message translates to:
  /// **'You can unblock any user or store anytime.'**
  String get settingsBlockedAccountsYouCanUnblockAnyUser;

  /// No description provided for @settingsBlockedAccountsBlockedStore.
  ///
  /// In en, this message translates to:
  /// **'Blocked store'**
  String get settingsBlockedAccountsBlockedStore;

  /// No description provided for @settingsBlockedAccountsBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'Blocked user'**
  String get settingsBlockedAccountsBlockedUser;

  /// No description provided for @settingsBugReportQuickTrigger.
  ///
  /// In en, this message translates to:
  /// **'Quick trigger'**
  String get settingsBugReportQuickTrigger;

  /// No description provided for @settingsBugReportDiagnosticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics summary'**
  String get settingsBugReportDiagnosticsSummary;

  /// No description provided for @settingsBugReportPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get settingsBugReportPlatform;

  /// No description provided for @settingsBugReportActiveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Active language'**
  String get settingsBugReportActiveLanguage;

  /// No description provided for @settingsBugReportHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsBugReportHelpSupport;

  /// No description provided for @settingsLanguageCouldNotSaveLanguagePlease.
  ///
  /// In en, this message translates to:
  /// **'Could not save language. Please try again.'**
  String get settingsLanguageCouldNotSaveLanguagePlease;

  /// No description provided for @settingsLanguageAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageAppLanguage;

  /// No description provided for @settingsLanguageChooseLanguageAppInterfaceListings.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app interface and listings. Changes apply immediately across the app.'**
  String get settingsLanguageChooseLanguageAppInterfaceListings;

  /// No description provided for @settingsRateAppNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get settingsRateAppNeedsWork;

  /// No description provided for @settingsRateAppFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get settingsRateAppFair;

  /// No description provided for @settingsRateAppGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get settingsRateAppGreat;

  /// No description provided for @settingsRateAppAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get settingsRateAppAwesome;

  /// No description provided for @settingsRateAppSelectStars.
  ///
  /// In en, this message translates to:
  /// **'Select stars'**
  String get settingsRateAppSelectStars;

  /// No description provided for @settingsRateAppPleaseSelect15Stars.
  ///
  /// In en, this message translates to:
  /// **'Please select 1 to 5 stars.'**
  String get settingsRateAppPleaseSelect15Stars;

  /// No description provided for @settingsRateAppRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get settingsRateAppRateApp;

  /// No description provided for @settingsRateAppHowIsExperienceApoloMa.
  ///
  /// In en, this message translates to:
  /// **'How is your experience with Apolo.ma?'**
  String get settingsRateAppHowIsExperienceApoloMa;

  /// No description provided for @settingsRateAppAddQuickNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a quick note (optional)...'**
  String get settingsRateAppAddQuickNoteOptional;

  /// No description provided for @settingsRateAppThankYouRatingUsRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for rating us {rating}/5!'**
  String settingsRateAppThankYouRatingUsRating(Object rating);

  /// No description provided for @settingsRateAppSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get settingsRateAppSubmitRating;

  /// No description provided for @settingsRateAppVisitApoloMa.
  ///
  /// In en, this message translates to:
  /// **'Visit Apolo.ma'**
  String get settingsRateAppVisitApoloMa;

  /// No description provided for @settingsSavedAdsCouldNotRemoveSavedListing.
  ///
  /// In en, this message translates to:
  /// **'Could not remove saved listing. Please try again.'**
  String get settingsSavedAdsCouldNotRemoveSavedListing;

  /// No description provided for @settingsSavedAdsSignViewSavedListings.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view saved listings'**
  String get settingsSavedAdsSignViewSavedListings;

  /// No description provided for @settingsSavedAdsSaveListingsYouLikeRevisit.
  ///
  /// In en, this message translates to:
  /// **'Save listings you like to revisit them anytime.'**
  String get settingsSavedAdsSaveListingsYouLikeRevisit;

  /// No description provided for @settingsSavedAdsCouldNotLoadSavedListings.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved listings'**
  String get settingsSavedAdsCouldNotLoadSavedListings;

  /// No description provided for @settingsSavedAdsCheckInternetConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get settingsSavedAdsCheckInternetConnectionTryAgain;

  /// No description provided for @settingsSavedAdsTapFavoriteIconAnyListing.
  ///
  /// In en, this message translates to:
  /// **'Tap the favorite icon on any listing to save it here.'**
  String get settingsSavedAdsTapFavoriteIconAnyListing;

  /// No description provided for @settingsShareAppCheckOutApoloMaMorocco.
  ///
  /// In en, this message translates to:
  /// **'Check out Apolo.ma — Morocco’s classifieds & stores marketplace: {shareUrl}'**
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl);

  /// No description provided for @settingsShareAppShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get settingsShareAppShareApp;

  /// No description provided for @settingsShareAppMoroccoSMarketplaceClassifiedsOfficial.
  ///
  /// In en, this message translates to:
  /// **'Morocco’s marketplace for classifieds and official stores. Share with friends and family.'**
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial;

  /// No description provided for @settingsShareAppAppLinkCopiedShareurl.
  ///
  /// In en, this message translates to:
  /// **'App link copied: {shareUrl}'**
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl);

  /// No description provided for @settingsShareAppShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get settingsShareAppShareNow;

  /// No description provided for @settingsShareAppCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get settingsShareAppCopyLink;

  /// No description provided for @settingsShareAppShareMyQrProfile.
  ///
  /// In en, this message translates to:
  /// **'Share my QR profile'**
  String get settingsShareAppShareMyQrProfile;

  /// No description provided for @settingsSuggestionPleaseEnterSuggestionAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Please enter a suggestion of at least 5 characters.'**
  String get settingsSuggestionPleaseEnterSuggestionAtLeast;

  /// No description provided for @settingsSuggestionCouldNotSendOverNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not send over the network right now. Try again or send via email.'**
  String get settingsSuggestionCouldNotSendOverNetwork;

  /// No description provided for @settingsSuggestionCopiedSupportApoloMa.
  ///
  /// In en, this message translates to:
  /// **'Copied support@apolo.ma'**
  String get settingsSuggestionCopiedSupportApoloMa;

  /// No description provided for @settingsSuggestionFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get settingsSuggestionFeature;

  /// No description provided for @settingsSuggestionDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get settingsSuggestionDesign;

  /// No description provided for @settingsSuggestionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get settingsSuggestionPerformance;

  /// No description provided for @settingsSuggestionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settingsSuggestionOther;

  /// No description provided for @settingsSuggestionMakeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Make a suggestion'**
  String get settingsSuggestionMakeSuggestion;

  /// No description provided for @settingsSuggestionShareIdeasHelpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Share your ideas to help us improve Apolo.ma.'**
  String get settingsSuggestionShareIdeasHelpUsImprove;

  /// No description provided for @settingsSuggestionTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get settingsSuggestionTopic;

  /// No description provided for @settingsSuggestionYourSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion'**
  String get settingsSuggestionYourSuggestion;

  /// No description provided for @settingsSuggestionWriteIdeaHere.
  ///
  /// In en, this message translates to:
  /// **'Write your idea here...'**
  String get settingsSuggestionWriteIdeaHere;

  /// No description provided for @settingsSuggestionThankYouSuggestionHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your suggestion has been received.'**
  String get settingsSuggestionThankYouSuggestionHasBeen;

  /// No description provided for @settingsSuggestionSubmitSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Submit suggestion'**
  String get settingsSuggestionSubmitSuggestion;

  /// No description provided for @settingsSuggestionEmailSupportApoloMa.
  ///
  /// In en, this message translates to:
  /// **'Email support@apolo.ma'**
  String get settingsSuggestionEmailSupportApoloMa;

  /// No description provided for @settingsZoneMarketplaceZone.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Zone'**
  String get settingsZoneMarketplaceZone;

  /// No description provided for @logOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutButton;

  /// No description provided for @settingsLogOutAccount.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account?'**
  String get settingsLogOutAccount;

  /// No description provided for @settingsYouCanSignBackAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime to access your listings and messages.'**
  String get settingsYouCanSignBackAnytime;

  /// No description provided for @settingsProActive.
  ///
  /// In en, this message translates to:
  /// **'PRO+ Active'**
  String get settingsProActive;

  /// No description provided for @settingsNotSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Not subscribed'**
  String get settingsNotSubscribed;

  /// No description provided for @settingsVipBoostCredits.
  ///
  /// In en, this message translates to:
  /// **'VIP Boost Credits'**
  String get settingsVipBoostCredits;

  /// No description provided for @settingsPrivacyTerms.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get settingsPrivacyTerms;

  /// No description provided for @settingsAppDataLicenses.
  ///
  /// In en, this message translates to:
  /// **'App data & licenses'**
  String get settingsAppDataLicenses;

  /// No description provided for @settingsActivity.
  ///
  /// In en, this message translates to:
  /// **'Settings and activity'**
  String get settingsActivity;

  /// No description provided for @settingsNoMatchingSettings.
  ///
  /// In en, this message translates to:
  /// **'No matching settings'**
  String get settingsNoMatchingSettings;

  /// No description provided for @settingsTryAnotherKeywordSuchAs.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword such as Saved, Language, or Pro+.'**
  String get settingsTryAnotherKeywordSuchAs;

  /// No description provided for @settingsYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get settingsYourAccount;

  /// No description provided for @settingsHowYouUseApolo.
  ///
  /// In en, this message translates to:
  /// **'How you use Apolo'**
  String get settingsHowYouUseApolo;

  /// No description provided for @settingsSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get settingsSubscriptions;

  /// No description provided for @settingsCommunityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Community & Privacy'**
  String get settingsCommunityPrivacy;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsPasswordSecurityPersonalDetailsStore.
  ///
  /// In en, this message translates to:
  /// **'Password, security, personal details, store & business'**
  String get settingsPasswordSecurityPersonalDetailsStore;

  /// No description provided for @shareProfileProfileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get shareProfileProfileLinkCopied;

  /// No description provided for @shareProfileCheckOutNameHandleApolo.
  ///
  /// In en, this message translates to:
  /// **'Check out {name} ({handle}) on Apolo.ma:\n{url}'**
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url);

  /// No description provided for @shareProfileShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareProfileShareLink;

  /// No description provided for @shareProfileQrCodeIsPrivateIf.
  ///
  /// In en, this message translates to:
  /// **'Your QR code is private. If you share it with someone, that person can scan it with their camera to add you as a contact.'**
  String get shareProfileQrCodeIsPrivateIf;

  /// No description provided for @shareProfileScanCode.
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get shareProfileScanCode;

  /// No description provided for @storeDetailReportStore.
  ///
  /// In en, this message translates to:
  /// **'Report store'**
  String get storeDetailReportStore;

  /// No description provided for @storeDetailStoreBlocked.
  ///
  /// In en, this message translates to:
  /// **'Store blocked'**
  String get storeDetailStoreBlocked;

  /// No description provided for @storeDetailBlockStore.
  ///
  /// In en, this message translates to:
  /// **'Block store'**
  String get storeDetailBlockStore;

  /// No description provided for @storeDetailDirectStoreOrder.
  ///
  /// In en, this message translates to:
  /// **'Direct Store Order'**
  String get storeDetailDirectStoreOrder;

  /// No description provided for @storeDetailSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Select item'**
  String get storeDetailSelectItem;

  /// No description provided for @storeDetailFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get storeDetailFullName;

  /// No description provided for @storeDetailDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get storeDetailDeliveryAddress;

  /// No description provided for @storeDetailOrderNotes.
  ///
  /// In en, this message translates to:
  /// **'Order notes'**
  String get storeDetailOrderNotes;

  /// No description provided for @storeDetailConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get storeDetailConfirmOrder;

  /// No description provided for @storeDetailOrderSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order submitted successfully'**
  String get storeDetailOrderSubmittedSuccessfully;

  /// No description provided for @storeDetailStoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'Store not found'**
  String get storeDetailStoreNotFound;

  /// No description provided for @storeDetailCheckLinkBrowseVerifiedStores.
  ///
  /// In en, this message translates to:
  /// **'Check the link or browse verified stores.'**
  String get storeDetailCheckLinkBrowseVerifiedStores;

  /// No description provided for @storeDetailOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Order now'**
  String get storeDetailOrderNow;

  /// No description provided for @storeDetailOpenWorkinghours.
  ///
  /// In en, this message translates to:
  /// **'Open · {workingHours}'**
  String storeDetailOpenWorkinghours(Object workingHours);

  /// No description provided for @storeDetailClosedWorkinghours.
  ///
  /// In en, this message translates to:
  /// **'Closed · {workingHours}'**
  String storeDetailClosedWorkinghours(Object workingHours);

  /// No description provided for @storeDetailOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get storeDetailOpenGoogleMaps;

  /// No description provided for @storeDetailOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get storeDetailOrder;

  /// No description provided for @storeDetailProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get storeDetailProducts;

  /// No description provided for @verifiedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadgeLabel;

  /// No description provided for @storeDetailDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get storeDetailDelivery;

  /// No description provided for @storeDetailStoreCatalog.
  ///
  /// In en, this message translates to:
  /// **'Store Catalog'**
  String get storeDetailStoreCatalog;

  /// No description provided for @storesTotalstoresVerifiedOfficialStores.
  ///
  /// In en, this message translates to:
  /// **'{totalStores} verified official stores'**
  String storesTotalstoresVerifiedOfficialStores(Object totalStores);

  /// No description provided for @storesSearchOfficialStores.
  ///
  /// In en, this message translates to:
  /// **'Search official stores...'**
  String get storesSearchOfficialStores;

  /// No description provided for @storesMostProducts.
  ///
  /// In en, this message translates to:
  /// **'Most products'**
  String get storesMostProducts;

  /// No description provided for @storesTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get storesTopRated;

  /// No description provided for @storesNoMatchingStores.
  ///
  /// In en, this message translates to:
  /// **'No matching stores'**
  String get storesNoMatchingStores;

  /// No description provided for @storesTryAnotherKeywordReloadVerified.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword or reload the verified stores list.'**
  String get storesTryAnotherKeywordReloadVerified;

  /// No description provided for @storesItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get storesItems;

  /// No description provided for @storesVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get storesVisit;

  /// No description provided for @supportCouldNotOpenMailApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open your mail app. Please email support@apolo.ma manually.'**
  String get supportCouldNotOpenMailApp;

  /// No description provided for @supportHowCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get supportHowCanWeHelpYou;

  /// No description provided for @supportExplainIssueStepsBeforeIt.
  ///
  /// In en, this message translates to:
  /// **'Explain the issue and the steps before it. You may attach a screenshot after masking personal details.'**
  String get supportExplainIssueStepsBeforeIt;

  /// No description provided for @supportDirectContact.
  ///
  /// In en, this message translates to:
  /// **'Direct contact'**
  String get supportDirectContact;

  /// No description provided for @supportOpenMailApp.
  ///
  /// In en, this message translates to:
  /// **'Open Mail App'**
  String get supportOpenMailApp;

  /// No description provided for @supportNoEmailIsSentAutomatically.
  ///
  /// In en, this message translates to:
  /// **'No email is sent automatically. Review and send it from your mail app.'**
  String get supportNoEmailIsSentAutomatically;

  /// No description provided for @supportSafetyReminder.
  ///
  /// In en, this message translates to:
  /// **'Safety reminder'**
  String get supportSafetyReminder;

  /// No description provided for @supportNeverSharePasswordVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Never share your password, verification code, or payment details with anyone.'**
  String get supportNeverSharePasswordVerificationCode;

  /// No description provided for @welcomeUnableStartGoogleSignRight.
  ///
  /// In en, this message translates to:
  /// **'Unable to start Google sign-in right now.'**
  String get welcomeUnableStartGoogleSignRight;

  /// No description provided for @welcomeContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get welcomeContinueGoogle;

  /// No description provided for @welcomeOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get welcomeOr;

  /// No description provided for @welcomeIHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I have an account'**
  String get welcomeIHaveAccount;

  /// No description provided for @welcomeNewOfferReceivedListing.
  ///
  /// In en, this message translates to:
  /// **'New offer received on your listing!'**
  String get welcomeNewOfferReceivedListing;

  /// No description provided for @welcomeY.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get welcomeY;

  /// No description provided for @welcomeYassineCasablanca.
  ///
  /// In en, this message translates to:
  /// **'Yassine • Casablanca'**
  String get welcomeYassineCasablanca;

  /// No description provided for @welcomeYesAvailableWelcome.
  ///
  /// In en, this message translates to:
  /// **'Yes available, welcome!'**
  String get welcomeYesAvailableWelcome;

  /// No description provided for @accommodationCardSintraPortugal.
  ///
  /// In en, this message translates to:
  /// **'Sintra, Portugal'**
  String get accommodationCardSintraPortugal;

  /// No description provided for @accommodationCardExclusiveDeal.
  ///
  /// In en, this message translates to:
  /// **'Exclusive deal'**
  String get accommodationCardExclusiveDeal;

  /// No description provided for @adCardVip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get adCardVip;

  /// No description provided for @safetyReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get safetyReportMessage;

  /// No description provided for @safetyReportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get safetyReportListing;

  /// No description provided for @safetyReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get safetyReportUser;

  /// No description provided for @safetyAlsoBlockThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Also block this account'**
  String get safetyAlsoBlockThisAccount;

  /// No description provided for @safetySubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get safetySubmitReport;

  /// No description provided for @safetyReportSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get safetyReportSubmittedSuccessfully;

  /// No description provided for @safetyBlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked Accounts'**
  String get safetyBlockedAccounts;

  /// No description provided for @boostCouldNotCompletePayment.
  ///
  /// In en, this message translates to:
  /// **'Could not complete payment'**
  String get boostCouldNotCompletePayment;

  /// No description provided for @boostListingBoosted.
  ///
  /// In en, this message translates to:
  /// **'Listing boosted!'**
  String get boostListingBoosted;

  /// No description provided for @boostPaymentNotConfirmedContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Payment not confirmed. Contact support before retrying.'**
  String get boostPaymentNotConfirmedContactSupport;

  /// No description provided for @boostVipBoostActivatedUsingPro.
  ///
  /// In en, this message translates to:
  /// **'VIP Boost activated using your Pro+ credit!'**
  String get boostVipBoostActivatedUsingPro;

  /// No description provided for @boostListing.
  ///
  /// In en, this message translates to:
  /// **'Boost your listing'**
  String get boostListing;

  /// No description provided for @boostActivateFreeVipProVipboostcredits.
  ///
  /// In en, this message translates to:
  /// **'Activate free VIP with Pro+ ({vipBoostCredits})'**
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits);

  /// No description provided for @boostGet3FreeVipBoosts.
  ///
  /// In en, this message translates to:
  /// **'Get 3 free VIP boosts/month with Apolo Pro+'**
  String get boostGet3FreeVipBoosts;

  /// No description provided for @boostPlansAreCurrentlyUnavailablePlease.
  ///
  /// In en, this message translates to:
  /// **'Plans are currently unavailable. Please try again later.'**
  String get boostPlansAreCurrentlyUnavailablePlease;

  /// No description provided for @boostInstantWebCheckoutIsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Instant web checkout is enabled for your account.'**
  String get boostInstantWebCheckoutIsEnabled;

  /// No description provided for @boostActivateBoostNow.
  ///
  /// In en, this message translates to:
  /// **'Activate Boost now'**
  String get boostActivateBoostNow;

  /// No description provided for @chatUtilsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatUtilsYesterday;

  /// No description provided for @guestFavoriteBadge.
  ///
  /// In en, this message translates to:
  /// **'Guest favorite'**
  String get guestFavoriteBadge;

  /// No description provided for @exploreListingCardContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact seller'**
  String get exploreListingCardContactSeller;

  /// No description provided for @marketplaceZoneCouldNotAutoDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not auto-detect location — select your city below'**
  String get marketplaceZoneCouldNotAutoDetectLocation;

  /// No description provided for @marketplaceZoneMarketplaceLocation.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Location'**
  String get marketplaceZoneMarketplaceLocation;

  /// No description provided for @marketplaceZoneOnlySeeListingsInsideLocal.
  ///
  /// In en, this message translates to:
  /// **'Only see listings inside your local area'**
  String get marketplaceZoneOnlySeeListingsInsideLocal;

  /// No description provided for @marketplaceZoneSearchNeighborhoodCityAddress.
  ///
  /// In en, this message translates to:
  /// **'Search neighborhood, city, address...'**
  String get marketplaceZoneSearchNeighborhoodCityAddress;

  /// No description provided for @marketplaceZoneNationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get marketplaceZoneNationwide;

  /// No description provided for @marketplaceZoneDetectMyLocationAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Detect my location automatically'**
  String get marketplaceZoneDetectMyLocationAutomatically;

  /// No description provided for @marketplaceZoneDistanceRadius.
  ///
  /// In en, this message translates to:
  /// **'Distance radius'**
  String get marketplaceZoneDistanceRadius;

  /// No description provided for @marketplaceZoneAllMorocco.
  ///
  /// In en, this message translates to:
  /// **'All of Morocco'**
  String get marketplaceZoneAllMorocco;

  /// No description provided for @marketplaceZoneSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get marketplaceZoneSelectCity;

  /// No description provided for @marketplaceZoneApplyZone.
  ///
  /// In en, this message translates to:
  /// **'Apply zone'**
  String get marketplaceZoneApplyZone;

  /// No description provided for @quickRepliesLimitReachedMaxallowedUpgradePro.
  ///
  /// In en, this message translates to:
  /// **'Limit reached ({maxAllowed}). Upgrade to Pro Plus for more!'**
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed);

  /// No description provided for @quickRepliesQuickRepliesSaved.
  ///
  /// In en, this message translates to:
  /// **'Quick replies saved ⚡'**
  String get quickRepliesQuickRepliesSaved;

  /// No description provided for @quickRepliesChatQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Chat Quick Replies'**
  String get quickRepliesChatQuickReplies;

  /// No description provided for @quickRepliesTapAnyShortcutInsideChat.
  ///
  /// In en, this message translates to:
  /// **'Tap any shortcut inside Chat to reply to buyers in one tap.'**
  String get quickRepliesTapAnyShortcutInsideChat;

  /// No description provided for @quickRepliesAddQuickReply.
  ///
  /// In en, this message translates to:
  /// **'Add quick reply'**
  String get quickRepliesAddQuickReply;

  /// No description provided for @quickRepliesLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get quickRepliesLabel;

  /// No description provided for @quickRepliesReplyText.
  ///
  /// In en, this message translates to:
  /// **'Reply text...'**
  String get quickRepliesReplyText;

  /// No description provided for @quickRepliesAutoGreetingMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto-greeting message'**
  String get quickRepliesAutoGreetingMessage;

  /// No description provided for @quickRepliesWelcomeStore.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our store!'**
  String get quickRepliesWelcomeStore;

  /// No description provided for @quickRepliesSaveQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Save Quick Replies'**
  String get quickRepliesSaveQuickReplies;

  /// No description provided for @quickRepliesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get quickRepliesManage;

  /// No description provided for @realMarketplaceMapApproximateMapArea.
  ///
  /// In en, this message translates to:
  /// **'Approximate map area'**
  String get realMarketplaceMapApproximateMapArea;

  /// No description provided for @realMarketplaceMapDistkmKmFromYou.
  ///
  /// In en, this message translates to:
  /// **'{distKm} km from you'**
  String realMarketplaceMapDistkmKmFromYou(Object distKm);

  /// No description provided for @realMarketplaceMapSetAsMyZone.
  ///
  /// In en, this message translates to:
  /// **'Set as my zone'**
  String get realMarketplaceMapSetAsMyZone;

  /// No description provided for @badgesKitBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get badgesKitBronze;

  /// No description provided for @badgesKitSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get badgesKitSilver;

  /// No description provided for @badgesKitGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get badgesKitGold;

  /// No description provided for @badgesKitPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get badgesKitPlatinum;

  /// No description provided for @badgesKitDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get badgesKitDiamond;

  /// No description provided for @badgesKitChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get badgesKitChampion;

  /// No description provided for @badgesKitStarterMemberApolo.
  ///
  /// In en, this message translates to:
  /// **'Starter member on Apolo'**
  String get badgesKitStarterMemberApolo;

  /// No description provided for @badgesKitVerifiedAccount2Listings.
  ///
  /// In en, this message translates to:
  /// **'Verified account or 2+ listings'**
  String get badgesKitVerifiedAccount2Listings;

  /// No description provided for @badgesKitBusinessStore5Listings.
  ///
  /// In en, this message translates to:
  /// **'Business store or 5+ listings'**
  String get badgesKitBusinessStore5Listings;

  /// No description provided for @badgesKitActiveProActiveStore8.
  ///
  /// In en, this message translates to:
  /// **'Active Pro+ or active store (8+)'**
  String get badgesKitActiveProActiveStore8;

  /// No description provided for @badgesKitPro10Listings1500.
  ///
  /// In en, this message translates to:
  /// **'Pro+ with 10+ listings or 1,500 views'**
  String get badgesKitPro10Listings1500;

  /// No description provided for @badgesKitTopTierPro20Listings.
  ///
  /// In en, this message translates to:
  /// **'Top tier: Pro+ with 20+ listings or 5,000 views'**
  String get badgesKitTopTierPro20Listings;

  /// No description provided for @badgesKitSellerRank.
  ///
  /// In en, this message translates to:
  /// **'Seller rank:'**
  String get badgesKitSellerRank;

  /// No description provided for @badgesKitTopRankUnlockedApolo.
  ///
  /// In en, this message translates to:
  /// **'Top rank unlocked on Apolo!'**
  String get badgesKitTopRankUnlockedApolo;

  /// No description provided for @badgesKitNext.
  ///
  /// In en, this message translates to:
  /// **'Next:'**
  String get badgesKitNext;

  /// No description provided for @badgesKitTrustSellerRanks.
  ///
  /// In en, this message translates to:
  /// **'Trust & Seller Ranks'**
  String get badgesKitTrustSellerRanks;

  /// No description provided for @badgesKitCurrentRank.
  ///
  /// In en, this message translates to:
  /// **'Current rank:'**
  String get badgesKitCurrentRank;

  /// No description provided for @badgesKitVerifiedApoloAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified Apolo Account'**
  String get badgesKitVerifiedApoloAccount;

  /// No description provided for @badgesKitVerifiedSeal.
  ///
  /// In en, this message translates to:
  /// **'Verified Seal'**
  String get badgesKitVerifiedSeal;

  /// No description provided for @badgesKitIdentityContactDetailsVerifiedSafer.
  ///
  /// In en, this message translates to:
  /// **'Identity and contact details verified for safer transactions.'**
  String get badgesKitIdentityContactDetailsVerifiedSafer;

  /// No description provided for @badgesKitEarnedByVerifyingPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Earned by verifying your phone number or activating a Pro store.'**
  String get badgesKitEarnedByVerifyingPhoneNumber;

  /// No description provided for @badgesKitAllSellerRanks.
  ///
  /// In en, this message translates to:
  /// **'All Seller Ranks'**
  String get badgesKitAllSellerRanks;

  /// No description provided for @badgesKitCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get badgesKitCurrent;

  /// No description provided for @infeedUpgradeCardYourProfile.
  ///
  /// In en, this message translates to:
  /// **'your_profile'**
  String get infeedUpgradeCardYourProfile;

  /// No description provided for @infeedUpgradeCardBuildCredibilityBuyersWhenYou.
  ///
  /// In en, this message translates to:
  /// **'Build credibility with buyers when you subscribe to Apolo Premium.'**
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou;

  /// No description provided for @infeedUpgradeCardUpgradeProfile.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your profile'**
  String get infeedUpgradeCardUpgradeProfile;

  /// No description provided for @infeedUpgradeCardNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get infeedUpgradeCardNotNow;

  /// No description provided for @searchSuggestionsSearchUsernames.
  ///
  /// In en, this message translates to:
  /// **'Search for usernames'**
  String get searchSuggestionsSearchUsernames;

  /// No description provided for @searchSuggestionsSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get searchSuggestionsSuggestions;

  /// No description provided for @searchSuggestionsRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchSuggestionsRecentSearches;

  /// No description provided for @searchSuggestionsPopularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular searches'**
  String get searchSuggestionsPopularSearches;

  /// No description provided for @followedButton.
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get followedButton;

  /// No description provided for @writeReviewExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get writeReviewExcellent;

  /// No description provided for @writeReviewVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get writeReviewVeryGood;

  /// No description provided for @writeReviewPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get writeReviewPoor;

  /// No description provided for @writeReviewGreatCommunication.
  ///
  /// In en, this message translates to:
  /// **'Great communication'**
  String get writeReviewGreatCommunication;

  /// No description provided for @writeReviewAsDescribed.
  ///
  /// In en, this message translates to:
  /// **'As described'**
  String get writeReviewAsDescribed;

  /// No description provided for @writeReviewFastResponse.
  ///
  /// In en, this message translates to:
  /// **'Fast response'**
  String get writeReviewFastResponse;

  /// No description provided for @writeReviewFairPrice.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get writeReviewFairPrice;

  /// No description provided for @writeReviewReviewHasBeenPosted.
  ///
  /// In en, this message translates to:
  /// **'Your review has been posted'**
  String get writeReviewReviewHasBeenPosted;

  /// No description provided for @writeReviewShareExperienceThisSeller.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with this seller...'**
  String get writeReviewShareExperienceThisSeller;

  /// No description provided for @writeReviewUpdateReview.
  ///
  /// In en, this message translates to:
  /// **'Update review'**
  String get writeReviewUpdateReview;

  /// No description provided for @writeReviewSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get writeReviewSubmitReview;

  /// No description provided for @interestsSurveyWhatAreInterests.
  ///
  /// In en, this message translates to:
  /// **'What are your interests?'**
  String get interestsSurveyWhatAreInterests;

  /// No description provided for @interestsSurveyDiscoverProducts.
  ///
  /// In en, this message translates to:
  /// **'Discover products'**
  String get interestsSurveyDiscoverProducts;

  /// No description provided for @interestsSurveySaveContinueSelectedcategoryids.
  ///
  /// In en, this message translates to:
  /// **'Save & continue ({selectedCategoryIds})'**
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds);

  /// No description provided for @interestsSurveySkipNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get interestsSurveySkipNow;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get conditionLikeNew;

  /// No description provided for @conditionUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get conditionUsed;

  /// No description provided for @fulfillmentMeetInPerson.
  ///
  /// In en, this message translates to:
  /// **'Meet in person'**
  String get fulfillmentMeetInPerson;

  /// No description provided for @fulfillmentDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get fulfillmentDelivery;

  /// No description provided for @listingStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get listingStatusSold;

  /// No description provided for @listingStatusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get listingStatusReserved;

  /// No description provided for @safetyTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety tips'**
  String get safetyTipsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'ja'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
