// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chatPlaceholder => 'Message seller...';

  @override
  String get chatTypeMessageHint => 'Type a message...';

  @override
  String get chatRecordingPlaceholder => 'Recording...';

  @override
  String get chatAddAttachmentTooltip => 'Add attachment';

  @override
  String get chatMessageInputLabel => 'Message input';

  @override
  String get chatSendMessageTooltip => 'Send message';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return 'Staged attachment: $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return 'Remove attachment $name';
  }

  @override
  String get chatDismissMessageMenu => 'Dismiss Message Menu';

  @override
  String get chatJumpToLatest => 'Jump to latest';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count new $messageWord. Jump to latest';
  }

  @override
  String get chatMessageSingular => 'message';

  @override
  String get chatMessagePlural => 'messages';

  @override
  String get chatCallAndOptionsTooltip => 'Call and chat options';

  @override
  String get chatSendFailedRetrySemantic =>
      ', Send failed, double tap to retry';

  @override
  String get chatSendingSemantic => ', Sending';

  @override
  String get chatEditedLabel => 'Edited';

  @override
  String get chatRetrySendingTooltip => 'Retry sending message';

  @override
  String get chatTypingIndicatorLabel => 'Typing...';

  @override
  String get chatPhotoPreviewLabel => '📷 Photo';

  @override
  String get chatVoicePreviewLabel => '🎤 Voice message';

  @override
  String get voiceMicMutedIdleSemantic =>
      'Mic muted. No audio detected. Hold mic button to record voice message';

  @override
  String get voiceHoldToRecordSemantic =>
      'Hold to record voice message. Slide left to cancel, slide up to lock hands-free';

  @override
  String get voiceMicMutedSuffixSemantic =>
      '. Warning: Mic muted, no audio detected';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return 'Release to cancel voice recording$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Recording locked hands-free, $timeStr$mutedSuffix. Tap STOP to end recording';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Recording voice message, $timeStr$mutedSuffix. Slide left to cancel, slide up to lock';
  }

  @override
  String get voiceWaveformMutedSemantic => 'Flat audio waveform, mic muted';

  @override
  String get voiceWaveformPreviewSemantic =>
      'Interactive audio preview waveform';

  @override
  String get voiceWaveformLiveSemantic => 'Live audio waveform';

  @override
  String get voiceMicMutedWarningSemantic =>
      'Mic muted warning. No audio detected.';

  @override
  String get voiceMicMutedBadge => 'Mic muted';

  @override
  String get voiceCancelRecordingTooltip => 'Cancel voice recording';

  @override
  String get voicePauseRecordingTooltip => 'Pause voice recording or preview';

  @override
  String get voicePlayPreviewTooltip => 'Play voice preview';

  @override
  String get voiceSendVoiceMessageTooltip => 'Send voice message';

  @override
  String get voiceReleaseToCancelLabel => 'Release to cancel';

  @override
  String get voiceSlideToCancelLabel => 'Slide to cancel';

  @override
  String get voiceHoldMicPrompt => 'Hold mic to record voice message';

  @override
  String get voiceRecordButtonSemantic => 'Record voice message';

  @override
  String get voiceRecordGestureHint =>
      'Tap or press and hold to record. Slide inward to cancel, slide up to lock';

  @override
  String get voiceWaveformScrubberSemantic => 'Voice message waveform scrubber';

  @override
  String get voiceChatTitle => 'Voice Chat';

  @override
  String get voiceMicPermissionRequired =>
      'Microphone permission is required to record audio.';

  @override
  String get voiceCouldNotStartRecording =>
      'Could not start recording on this device.';

  @override
  String get voiceTapMicEmptyPrompt =>
      'Tap the microphone below to record a voice message';

  @override
  String get voiceTapMicInputHint => 'Tap mic to record voice note...';

  @override
  String get voiceToggleWaveformTooltip =>
      'Toggle fitWidth / longScroll waveform';

  @override
  String get voiceToggleThemeTooltip => 'Toggle GTA 6 theme';

  @override
  String get otpVerifyCodeTitle => 'Verify your code';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return 'Enter the 6-digit code sent to $destination';
  }

  @override
  String get otpCodeVerifiedLabel => 'Code verified';

  @override
  String get otpIncorrectCodeError => 'Code incorrect, try again';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResendCodeButton => 'Resend code';

  @override
  String get welcomeContinueAsGuestLabel => 'Continue as guest';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'Password';

  @override
  String get authFullNamePlaceholder => 'Name';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'username';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'Like, $count likes';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'Unlike, $count likes';
  }

  @override
  String get likeSyncFailedSemantic => 'Failed to save like. Tap to retry';

  @override
  String get pullToRefreshRefreshing => 'Refreshing list';

  @override
  String get pullToRefreshRelease => 'Release to refresh';

  @override
  String get pullToRefreshPullDown => 'Pull down to refresh';

  @override
  String get badgeOnlineSemantic => 'Online';

  @override
  String get badgeUnreadNotificationSemantic => 'Unread notification';

  @override
  String get badgeUnreadMaxSemantic => '99+ unread notifications';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '$count unread $notificationWord';
  }

  @override
  String get notificationSingular => 'notification';

  @override
  String get notificationPlural => 'notifications';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return 'React with $emoji';
  }

  @override
  String get emojiFewerTooltip => 'Fewer emojis';

  @override
  String get emojiMoreTooltip => 'More emojis';

  @override
  String get listingFavoriteTooltip => 'Favorite listing';

  @override
  String get accommodationFavoriteTooltip => 'Favorite accommodation';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedrooms bedrooms';
  }

  @override
  String get listingTaxesIncluded => 'taxes incl.';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '$total total · $nights nights';
  }

  @override
  String get boostActionLabel => 'Boost';

  @override
  String get liveBadgeLabel => 'LIVE';

  @override
  String get meetingEncryptionKeyHint => 'AES-GCM 256-bit Secret Key';

  @override
  String get meetingDefaultTitle => 'Apolo Meeting';

  @override
  String get meetingDefaultParticipantName => 'SFU Participant';

  @override
  String get bugReportSafetyHeader => 'Apolo.ma Safety';

  @override
  String get bugReportDescMinLengthError =>
      'Description must be at least 5 characters.';

  @override
  String get bugReportNetworkFailedError => 'Network request failed.';

  @override
  String get bugReportTimeoutError =>
      'Request timed out. Please check your connection and retry.';

  @override
  String get bugReportServerUnreachableError =>
      'Unable to reach Apolo.ma servers right now.';

  @override
  String get meetingSignInRequiredError =>
      'Please sign in to join the meeting.';

  @override
  String get meetingPermissionDeniedError =>
      'You do not have permission to access this meeting.';

  @override
  String get meetingAlreadyEndedError => 'This meeting has already ended.';

  @override
  String get meetingRoomLockedError =>
      'This room is currently locked by the host.';

  @override
  String get meetingMaxCapacityError =>
      'This meeting has reached its maximum participant capacity.';

  @override
  String get meetingServiceUnreachableError =>
      'Could not reach the meeting service. Check your connection.';

  @override
  String get accountOnboardingFormFinishSettingUpAccount =>
      'Finish setting up your account';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'Choose your city and interests. You can switch to a Business account for free anytime in Settings.';

  @override
  String get accountOnboardingFormCity => 'City';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      'Choose at least one interest';

  @override
  String get accountOnboardingFormSaveContinue => 'Save & continue';

  @override
  String get accountOnboardingFormReloadOptions => 'Reload options';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get sellItemButton => 'Post Ad';

  @override
  String get navStores => 'Stores';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get featuredAdsTitle => 'VIP Ads';

  @override
  String get latestAdsTitle => 'Latest Ads';

  @override
  String get allCitiesFilter => 'All Cities';

  @override
  String get allCategoriesFilter => 'All Categories';

  @override
  String get loginButton => 'Login';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get logoutButton => 'Logout';

  @override
  String get callSellerButton => 'Call';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get chatInAppButton => 'Chat';

  @override
  String get boostAdButton => 'Boost Ad';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get reportAdButton => 'Report Ad';

  @override
  String get blockUserButton => 'Block User';

  @override
  String get searchHint => 'Search for a car, apartment, phone...';

  @override
  String get noAdsFoundMessage => 'No ads found matching your search';

  @override
  String get appStateDark => 'Dark';

  @override
  String get appStateSystem => 'System';

  @override
  String get appStateLight => 'Light';

  @override
  String get appStateApoloMember => 'Apolo Member';

  @override
  String get appStateJustNow => 'Just now';

  @override
  String get appStateKm => 'km';

  @override
  String get bugReportReportTechnicalProblem => 'Report a technical problem';

  @override
  String get bugReportIfFeatureProductIsnT =>
      'If a feature or product isn\'t working correctly, you can share feedback to help us improve Apolo.ma.';

  @override
  String get bugReportReportProblem => 'Report a problem';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      'Reports about abuse or spam shouldn\'t be submitted here.';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'Learn how to report abuse, spam, fraud, or policy and safety violations on Apolo.ma.';

  @override
  String get bugReportShakePhoneReportProblem =>
      'Shake phone to report a problem';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'Enabled for mobile sensors (desktop browser has no accelerometer)';

  @override
  String get bugReportToggleEnable => 'Toggle on to enable';

  @override
  String get bugReportToggleOffDisable => 'Toggle off to disable';

  @override
  String get bugReportReportTechnicalProblem2 => 'Report technical problem';

  @override
  String get bugReportLearnMoreAboutReportingAbuse =>
      'Learn more about reporting abuse or spam';

  @override
  String get bugReportWouldYouLikeIncludeAdditional =>
      'Would you like to include additional logs and diagnostics?';

  @override
  String get bugReportAlwaysCollectedBasicContext =>
      'Always collected basic context:';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'Your authenticated user ID (if signed in), app version/build number, platform/OS, current screen/route name, and locale/RTL state.';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      'Optional diagnostics (only attached if you opt in):';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      'Recent in-memory log buffer, navigation and sanitized API error breadcrumbs, and device/viewport metadata to help reproduce the bug.';

  @override
  String get bugReportIncludeContinue => 'Include and continue';

  @override
  String get bugReportDonTIncludeContinue => 'Don\'t include and continue';

  @override
  String get sendButton => 'Send';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      'Briefly explain what happened or what\'s not working.';

  @override
  String get bugReportScreenshot => 'Screenshot';

  @override
  String get bugReportUpload => 'Upload';

  @override
  String get bugReportRemoveScreenshot => 'Remove screenshot';

  @override
  String get bugReportPreviewScreenshot => 'Preview screenshot';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'Auto-capture wasn\'t available on this view — you can use Upload instead.';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      'Please describe what happened before sending.';

  @override
  String get bugReportPleaseWriteAtLeast5 =>
      'Please write at least 5 characters to describe the issue.';

  @override
  String get bugReportImageExceeds5MbMaximum =>
      'Image exceeds the 5 MB maximum size limit.';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      'Unsupported image format. Please choose JPEG, PNG, or WebP.';

  @override
  String get bugReportCouldNotReadSelectedImage =>
      'Could not read the selected image.';

  @override
  String get retryButton => 'Retry';

  @override
  String get closeButton => 'Close';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return 'Thanks! Your technical report has been received (#$reportId)';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      'Thanks! Your technical report has been received.';

  @override
  String get bugReportCouldNotSendReportRight =>
      'Could not send the report right now. Check your connection and retry.';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return 'Too many reports sent recently. Please retry in $seconds seconds.';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      'Too many reports sent recently. Please wait a moment and retry.';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues =>
      'Reporting abuse, spam & safety issues';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'This form is strictly for technical bugs. To report suspicious listings, harassment, fraud, or policy violations on Apolo.ma, tap the Report option on that listing or chat, or open our safety reporting form below.';

  @override
  String get bugReportOpenSafetyAbuseReport => 'Open Safety & Abuse Report';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      'Found a bug or broken screen? Send a technical report with an optional screenshot.';

  @override
  String get meetingLobby => 'Meeting Lobby';

  @override
  String get meetingNewGroupMeeting => 'New Group Meeting';

  @override
  String get meetingJoinRoomCode => 'Join with Room Code';

  @override
  String get meetingTitle => 'Meeting Title';

  @override
  String get meetingEGLivePropertyWalkthrough =>
      'e.g. Live property walkthrough';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'Room code (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'Join Meeting';

  @override
  String get meetingStartMeeting => 'Start Meeting';

  @override
  String get meetingEndEndEncryptionE2ee => 'End-to-End Encryption (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'SFU forwards encrypted packets without ever seeing your media';

  @override
  String get meetingSharedRoomEncryptionKey => 'Shared Room Encryption Key';

  @override
  String get meetingAdaptiveSfuSvc25Participants =>
      'Adaptive SFU + SVC (25+ participants)';

  @override
  String get meetingMicOn => 'Mic On';

  @override
  String get meetingMuted => 'Muted';

  @override
  String get meetingCameraOn => 'Camera On';

  @override
  String get meetingCameraOff => 'Camera Off';

  @override
  String get meetingShareScreen => 'Share Screen';

  @override
  String get meetingStopSharing => 'Stop Sharing';

  @override
  String get meetingSpeaker => 'Speaker';

  @override
  String get meetingFlipCamera => 'Flip Camera';

  @override
  String get meetingParticipants => 'Participants';

  @override
  String get meetingLeave => 'Leave';

  @override
  String get meetingEndAll => 'End for All';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      'Unstable network... Automatically reconnecting via UDP/TURN';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      'Low bandwidth: video layers stepped down (SVC) to protect audio & battery';

  @override
  String get meetingAudioOnly => 'Audio Only';

  @override
  String get meetingResumeVideo => 'Resume Video';

  @override
  String get meetingDataBatterySaverAudioOnly =>
      'Data & battery saver (Audio-only) active';

  @override
  String get meetingYou => 'You';

  @override
  String get meetingHost => 'Host';

  @override
  String get meetingCoHost => 'Co-host';

  @override
  String get meetingLockRoom => 'Lock Room';

  @override
  String get meetingUnlockRoom => 'Unlock Room';

  @override
  String get meetingMuteMic => 'Mute Mic';

  @override
  String get meetingRemove => 'Remove';

  @override
  String get meetingCopyInviteLink => 'Copy Invite Link';

  @override
  String get meetingInviteCopied => 'Invite copied';

  @override
  String get meetingConnectingSecureSfuMediaRouter =>
      'Connecting to secure SFU media router...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get accountSecurityEnterValidEmailAddress =>
      'Enter a valid email address.';

  @override
  String get accountSecurityEnterValidPhoneNumber =>
      'Enter a valid phone number.';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      'Contact details updated successfully.';

  @override
  String get accountSecurityPasswordMustBeAtLeast =>
      'Password must be at least 8 characters.';

  @override
  String get accountSecurityPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully =>
      'Password updated successfully.';

  @override
  String get accountSecurityAccountSecurity => 'Account security';

  @override
  String get accountSecurityStayControlLogin => 'Stay in control of your login';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'Update your password, email, or phone directly in the app.';

  @override
  String get accountSecurityContactDetails => 'Contact details';

  @override
  String get accountSecurityEmailAddress => 'Email address';

  @override
  String get accountSecurityPhoneNumber => 'Phone number';

  @override
  String get accountSecuritySaveContactDetails => 'Save contact details';

  @override
  String get accountSecurityChangePassword => 'Change password';

  @override
  String get accountSecurityCurrentPassword => 'Current password';

  @override
  String get accountSecurityNewPassword => 'New password';

  @override
  String get accountSecurityConfirmNewPassword => 'Confirm new password';

  @override
  String get accountSecurityUpdatePassword => 'Update password';

  @override
  String get accountSecuritySecurityOptions => 'Security options';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'Sign in to update this information';

  @override
  String get accountSetupCreateAccount => 'Create account';

  @override
  String get accountSetupAccountType => 'Account type';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'Choose at least one profile type to personalize your setup.';

  @override
  String get continueButton => 'Continue';

  @override
  String get adDetailHiIsThisStillAvailable => 'Hi, is this still available?';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'Could not update favorites. Please try again.';

  @override
  String get adDetailPhoneNumberCopied => 'Phone number copied';

  @override
  String get adDetailCopy => 'Copy';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'Could not start conversation. Please try again.';

  @override
  String get adDetailUserBlocked => 'User blocked';

  @override
  String get adDetailReportThisListingAiContent =>
      'Report this listing or AI content';

  @override
  String get adDetailQuickReviewByTrustSafety =>
      'Quick review by our Trust & Safety team';

  @override
  String get adDetailHideAllListingsFromThis =>
      'Hide all listings from this seller';

  @override
  String get adDetailDetails => 'Details';

  @override
  String get adDetailListingUnavailable => 'Listing unavailable';

  @override
  String get adDetailThisItemMayHaveBeen =>
      'This item may have been sold or removed by the seller.';

  @override
  String get adDetailGoBack => 'Go back';

  @override
  String get adDetailCategory => 'Category';

  @override
  String get adDetailCondition => 'Condition';

  @override
  String get adDetailNotSpecified => 'Not specified';

  @override
  String get adDetailReference => 'Reference';

  @override
  String get backButton => 'Back';

  @override
  String get adDetailFavorite => 'Favorite';

  @override
  String get adDetailMore => 'More';

  @override
  String get adDetailFree => 'Free';

  @override
  String get adDetailOnRequest => 'On request';

  @override
  String get negotiableBadge => 'Negotiable';

  @override
  String get fixedPriceBadge => 'Fixed price';

  @override
  String get adDetailGuests => 'Guests';

  @override
  String get adDetailBedrooms => 'Bedrooms';

  @override
  String get adDetailBeds => 'Beds';

  @override
  String get adDetailBaths => 'Baths';

  @override
  String get adDetailGood => 'Good';

  @override
  String get adDetailRef => 'Ref';

  @override
  String get adDetailViews => 'Views';

  @override
  String get adDetailGuestFavourite => 'Guest favourite';

  @override
  String get adDetailVideoTour => 'Video tour';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return 'Just listed · ${m}m ago';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return 'Just listed · $h hours ago';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return '$d days ago';
  }

  @override
  String get adDetailJustListed => 'Just listed';

  @override
  String get adDetailBoostThisListing => 'Boost this listing ⚡';

  @override
  String get adDetailMessageSeller => 'Message seller';

  @override
  String get adDetailFastReply => 'Fast reply';

  @override
  String get adDetailWriteMessage => 'Write a message...';

  @override
  String get adDetailAlertsEnabledSimilarListings =>
      'Alerts enabled for similar listings';

  @override
  String get adDetailAlertsPaused => 'Alerts paused';

  @override
  String get adDetailAlerts => 'Alerts';

  @override
  String get adDetailMessage => 'Message';

  @override
  String get shareButton => 'Share';

  @override
  String get saveButton => 'Save';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      'No description provided. Message the seller for details.';

  @override
  String get adDetailDescription => 'Description';

  @override
  String get adDetailSeeLess => 'See less';

  @override
  String get adDetailSeeMore => 'See more';

  @override
  String get adDetailCallSeller => 'Call seller';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'Apolo Store · $cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'Apolo Seller · $cityName';
  }

  @override
  String get adDetailBusinessStore => 'Business Store';

  @override
  String get adDetailSeller => 'Seller';

  @override
  String get adDetailSeeReviews => 'See reviews';

  @override
  String get followingButton => 'Following';

  @override
  String get followButton => 'Follow';

  @override
  String get adDetailYourRating => 'Your rating';

  @override
  String get adDetailRateThisSeller => 'Rate this seller';

  @override
  String get adDetailEditReview => 'Edit review';

  @override
  String get adDetailWriteReview => 'Write review';

  @override
  String get adDetailLocation => 'Location';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'In your zone · $distKm km';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return '$distKm km away';
  }

  @override
  String get adDetailLocationIsApproximate => 'Location is approximate';

  @override
  String get adDetailFullMap => 'Full map';

  @override
  String get adDetailRelatedSearches => 'Related searches';

  @override
  String get adDetailIfYouDonTLike => 'If you don\'t like this, you can ';

  @override
  String get adDetailHideThisListing => 'hide this listing';

  @override
  String get adDetailWeLlShowYouFewer =>
      ' and we\'ll show you fewer listings like this.';

  @override
  String get adDetailListingHiddenFromFeed => 'Listing hidden from your feed';

  @override
  String get adDetailListingRestored => 'Listing restored';

  @override
  String get adDetailHidden => 'Hidden';

  @override
  String get adDetailHideListing => 'Hide listing';

  @override
  String get adDetailReportSafety => 'Report & Safety';

  @override
  String get adDetailSimilarListings => 'Similar listings';

  @override
  String get adDetailAllReviews => 'All Reviews';

  @override
  String get adDetailSellerRating => 'Seller rating';

  @override
  String get adDetailEditReview2 => 'Edit your review';

  @override
  String get adDetailWriteReview2 => 'Write a review';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return 'Seller reviews ($totalCount)';
  }

  @override
  String get adDetailShowAll => 'Show all';

  @override
  String get adDetail5Stars => '5 stars';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get adDetailHighest => 'Highest';

  @override
  String get adDetailSort => 'Sort';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return 'No written reviews for $sellerName yet';
  }

  @override
  String get adDetailHelpful => 'Helpful';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'Join me on Apolo.ma — Morocco’s marketplace: https://apolo.ma';

  @override
  String get addFriendsAddFriends => 'Add your friends';

  @override
  String get addFriendsInvited => 'Invited';

  @override
  String get addFriendsInvite => 'Invite';

  @override
  String get addFriendsContacts => 'Contacts';

  @override
  String get authUnableOpenGoogleSignRight =>
      'Unable to open Google sign-in right now.';

  @override
  String get authUnableStartGoogleSign => 'Unable to start Google sign-in.';

  @override
  String get authNoEmailAddressIsLinked =>
      'No email address is linked to this account to receive the code.';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return 'A verification code was sent to $masked.';
  }

  @override
  String get authPleaseEnterValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get authPasswordMustBeAtLeast =>
      'Your password must be at least 8 characters';

  @override
  String get authPleaseEnterNameAtLeast =>
      'Please enter your name (at least 2 characters)';

  @override
  String get authUsernameMustBeAtLeast =>
      'Username must be at least 3 letters or numbers';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      'Please enter a valid Moroccan phone number (e.g. 650-123456)';

  @override
  String get authEnter6DigitVerificationCode =>
      'Enter the 6-digit verification code.';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return 'A new verification code was sent to $masked.';
  }

  @override
  String get authNewVerificationCodeWasSent2 =>
      'A new verification code was sent to your email.';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue (Tried at $hh:$mm)';
  }

  @override
  String get signUpButton => 'Sign up';

  @override
  String get authEnterEmail => 'Enter your email';

  @override
  String get authEnterPassword => 'Enter your password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authWhatSEmail => 'What\'s your email?';

  @override
  String get authChoosePassword => 'Choose a password';

  @override
  String get authWhatSFirstName => 'What\'s your first name?';

  @override
  String get authPickUsername => 'Pick a username';

  @override
  String get authOthersCanFindYouUsername =>
      'Others can find you with your username!';

  @override
  String get authWhatSPhoneNumber => 'What\'s your phone number?';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'Enter a valid Moroccan phone number to secure your account';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return 'We sent a 6-digit verification code to $maskedEmail';
  }

  @override
  String get authWeSent6DigitVerification2 =>
      'We sent a 6-digit verification code to your email';

  @override
  String get authEnterVerificationCode => 'Enter verification code';

  @override
  String get authSending => 'Sending...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'Resend code (${remaining}s)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      'Welcome to our store on Apolo! How can we help you today?';

  @override
  String get businessSwitchPleaseEnterStoreNameAt =>
      'Please enter a store name (at least 2 characters).';

  @override
  String get businessSwitchPleaseEnterStoreName =>
      'Please enter your store name.';

  @override
  String get businessSwitchBusinessProfileUpdated =>
      'Business profile updated!';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      'Your Verified Business store is now active!';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'Could not save business profile. Please try again.';

  @override
  String get businessSwitchBusinessSettings => 'Business Settings';

  @override
  String get businessSwitchSwitchBusiness => 'Switch to Business';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      'Your previous store details are ready to reactivate!';

  @override
  String get savingLabel => 'Saving...';

  @override
  String get businessSwitchSaveChanges => 'Save Changes';

  @override
  String get businessSwitchActivateFreeBusiness => 'Activate Free Business';

  @override
  String get businessSwitchWhatBestDescribesBusiness =>
      'What best describes your business?';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'This category badge appears under your name on your profile and store.';

  @override
  String get businessSwitchStoreIdentityHoursLocation =>
      'Store identity, hours & location';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      'Your store appears in the Stores directory once you have at least 1 active listing.';

  @override
  String get businessSwitchStoreName => 'Store name *';

  @override
  String get businessSwitchEGAutoCasa => 'e.g. Auto Casa';

  @override
  String get businessSwitchBioDescription => 'Bio / Description';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      'Tell customers about your products & service...';

  @override
  String get businessSwitchCityAddress => 'City & address';

  @override
  String get businessSwitchEGMaarifCasablanca => 'e.g. Maarif, Casablanca';

  @override
  String get businessSwitchGoogleMapsLinkOptional =>
      'Google Maps link (optional)';

  @override
  String get businessSwitchWorkingHours => 'Working hours';

  @override
  String get businessSwitchContactDirectOrderTools =>
      'Contact & direct order tools';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'Enable 1-tap orders and automatic chat greetings.';

  @override
  String get businessSwitchBusinessPhone => 'Business phone';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      'Enable \"Direct Order\" button on store';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'Receive instant orders with customer details.';

  @override
  String get businessSwitchAutoGreetingMessageChat =>
      'Auto-greeting message in Chat';

  @override
  String get businessSwitchWelcomeStoreHowCanWe =>
      'Welcome to our store! How can we help?';

  @override
  String get callIncomingVideoCall => 'Incoming video call...';

  @override
  String get callIncomingVoiceCall => 'Incoming voice call...';

  @override
  String get callRinging => 'Ringing...';

  @override
  String get callAllowMicCameraAccess => 'Allow mic/camera access';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get callCalls => 'Calls';

  @override
  String get callCallsAreUnavailableThisDevice =>
      'Calls are unavailable on this device';

  @override
  String get callBackChat => 'Back to Chat';

  @override
  String get callVideoCall => 'Video Call';

  @override
  String get callVoiceCall => 'Voice Call';

  @override
  String get callDecline => 'Decline';

  @override
  String get callAccept => 'Accept';

  @override
  String get callMic => 'Mic';

  @override
  String get callCamera => 'Camera';

  @override
  String get callEnd => 'End';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return 'Last message $lastTime';
  }

  @override
  String get chatListUnpinChat => 'Unpin chat';

  @override
  String get chatListPinChat => 'Pin chat';

  @override
  String get chatListChatUnpinned => 'Chat unpinned';

  @override
  String get chatListChatPinnedTop => 'Chat pinned to top';

  @override
  String get chatListMarkAsRead => 'Mark as read';

  @override
  String get chatListUnmuteNotifications => 'Unmute notifications';

  @override
  String get chatListMuteNotifications => 'Mute notifications';

  @override
  String get chatListNotificationsUnmuted => 'Notifications unmuted';

  @override
  String get chatListChatMuted => 'Chat muted';

  @override
  String get chatListArchiveChat => 'Archive chat';

  @override
  String get chatListChatArchived => 'Chat archived';

  @override
  String get chatListReportChat => 'Report chat';

  @override
  String chatListBlockPeername(Object peerName) {
    return 'Block $peerName';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return 'Blocked $peerName';
  }

  @override
  String get chatListDeleteChat => 'Delete chat';

  @override
  String get chatListChatDeleted => 'Chat deleted';

  @override
  String get chatListSelectConversationStartMessaging =>
      'Select a conversation to start messaging';

  @override
  String get chatListChats => 'Chats';

  @override
  String get chatListMarkAllRead => 'Mark all read';

  @override
  String get searchTitle => 'Search';

  @override
  String get chatListAll => 'All';

  @override
  String get chatListUnread => 'Unread';

  @override
  String get chatListPinned => 'Pinned';

  @override
  String get chatListSignViewChats => 'Sign in to view your chats';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      'Message buyers and sellers directly and securely.';

  @override
  String get signInButton => 'Sign in';

  @override
  String get chatListNoUnreadChats => 'No unread chats';

  @override
  String get chatListNoPinnedChats => 'No pinned chats';

  @override
  String get chatListNoChatsYet => 'No chats yet';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      'Browse listings and message sellers directly.';

  @override
  String get chatListExploreListings => 'Explore listings';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      'Your personal messages are end-to-end encrypted';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'Failed to load messages. Please try again.';

  @override
  String get chatRoomMessageEdited => 'Message edited';

  @override
  String get chatRoomDeletedEveryone => 'Deleted for everyone';

  @override
  String get chatRoomMessagePinned => 'Message pinned';

  @override
  String get chatRoomMessageUnpinned => 'Message unpinned';

  @override
  String get chatRoomMessageStarred => 'Message starred ⭐';

  @override
  String get chatRoomStarRemoved => 'Star removed';

  @override
  String get chatRoomReportConversation => 'Report conversation';

  @override
  String get chatRoomUserUnblocked => 'User unblocked';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return 'Unblock $peerName';
  }

  @override
  String get chatRoomReply => 'Reply';

  @override
  String get chatRoomUnpin => 'Unpin';

  @override
  String get chatRoomPin => 'Pin';

  @override
  String get chatRoomUnstar => 'Unstar';

  @override
  String get chatRoomStar => 'Star';

  @override
  String get chatRoomCopied => 'Copied';

  @override
  String get editButton => 'Edit';

  @override
  String get reportButton => 'Report';

  @override
  String get deleteButton => 'Delete';

  @override
  String get chatRoomDeleteEveryone => 'Delete for everyone';

  @override
  String get chatRoomMorocco => 'Morocco';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 My location: $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 Price offer for \"$title\": DH $cleaned';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 Price offer: DH $cleaned';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      'Could not capture audio. Please allow microphone access and try again.';

  @override
  String get chatRoomVoiceMessageIsTooLong =>
      'Voice message is too long. Please record a shorter message.';

  @override
  String get chatRoomThisMessageWasDeleted => 'This message was deleted';

  @override
  String get chatRoomRead => 'Read';

  @override
  String get chatRoomDelivered => 'Delivered';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return 'Last seen $clock';
  }

  @override
  String get chatRoomOffline => 'Offline';

  @override
  String get chatRoomVideoCallUnavailable => 'Video Call — unavailable';

  @override
  String get chatRoomVoiceCallUnavailable => 'Voice Call — unavailable';

  @override
  String get chatRoomSafetyReport => 'Safety & Report';

  @override
  String get chatRoomYouBlockedThisUser => 'You blocked this user';

  @override
  String get chatRoomUnblock => 'Unblock';

  @override
  String get chatRoomEditingMessage => 'Editing message';

  @override
  String get chatRoomSendMessage => 'Send a message';

  @override
  String get editProfileMinimum3CharactersRequired =>
      'Minimum 3 characters required';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return '@$clean is available';
  }

  @override
  String get editProfileAlreadyTaken => 'Already taken.';

  @override
  String get editProfileProfilePhoto => 'Profile photo';

  @override
  String get editProfileChooseFromLibrary => 'Choose from library';

  @override
  String get editProfileTakePhoto => 'Take photo';

  @override
  String get editProfileRemoveCurrentPhoto => 'Remove current photo';

  @override
  String get editProfileChoosePresetAvatar => 'Or choose a preset avatar';

  @override
  String get editProfileSelectCity => 'Select your city';

  @override
  String get clearButton => 'Clear';

  @override
  String get editProfilePhoneWhatsapp => 'Phone & WhatsApp';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get editProfileNameIsRequired => 'Name is required.';

  @override
  String get editProfileUsernameMustBeAtLeast =>
      'Username must be at least 3 characters.';

  @override
  String get editProfileThisUsernameIsAlreadyTaken =>
      'This username is already taken.';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      'Could not save changes. Please try again.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileEditPicture => 'Edit picture';

  @override
  String get editProfileFullName => 'Your full name';

  @override
  String get editProfileUsername => 'Username';

  @override
  String get editProfileBio => 'Bio';

  @override
  String get editProfileWriteShortBioAboutYourself =>
      'Write a short bio about yourself...';

  @override
  String get editProfileAddCity => 'Add city';

  @override
  String get editProfilePhone => 'Phone';

  @override
  String get editProfileAddPhoneNumber => 'Add phone number';

  @override
  String get editProfileManageStoreDetails => 'Manage store details';

  @override
  String get editProfileGetVerifiedBusinessStore =>
      'Get Verified & Business Store';

  @override
  String get editProfilePersonalInformation => 'Personal information';

  @override
  String get editProfileEmailPasswordSettings => 'Email & password settings';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return 'We sent a 6-digit verification code to $masked.';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      'Please enter the 6-digit verification code.';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      'Password updated and signed in successfully!';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      'You will receive an email to set a new password';

  @override
  String get forgotPasswordChooseNewPassword => 'Choose a new password';

  @override
  String get homeInternetConnectionLost => 'Internet connection lost';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      'Check your network connection and try again to load listings.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get homeWelcomeApolo => 'Welcome to Apolo';

  @override
  String get homeSearchCarsHomesPhonesAccounts =>
      'Search cars, homes, phones, or accounts...';

  @override
  String get homeLatestListings => 'Latest listings';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'No listings within $zoneRadiusKm km of $s yet';
  }

  @override
  String get homeShowAllMorocco => 'Show all Morocco';

  @override
  String get homeChangeZone => 'Change zone';

  @override
  String get homeBrowseAllListingsMorocco => 'Browse all listings in Morocco';

  @override
  String get home1MarketplaceMorocco => '#1 Marketplace in Morocco 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen =>
      'Buy and sell safely without middlemen';

  @override
  String get homeCarsPhonesRealEstateDiscover =>
      'Cars, phones, real estate. Discover listings near you.';

  @override
  String get homeExclusiveDeals => 'Exclusive Deals';

  @override
  String get homeWhyChooseApolo => 'Why choose Apolo?';

  @override
  String get home0CommissionFree => '0% Commission & Free';

  @override
  String get homeBuySellFreeZeroMiddlemen =>
      'Buy and sell for free with zero middlemen.';

  @override
  String get homeDirectChatCall => 'Direct Chat & Call';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      'Message the seller directly and make an offer in one tap.';

  @override
  String get homeVerifiedListings => 'Verified Listings';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      'Continuous review to keep all transactions safe.';

  @override
  String get homeGotSomethingSellPostNow => 'Got something to sell? Post now';

  @override
  String get homePublishFree30SecondsGet =>
      'Publish free in 30 seconds and get buyer inquiries fast';

  @override
  String get homePost => 'Post +';

  @override
  String get homeVerifiedOfficialStores => 'Verified Official Stores';

  @override
  String get homeBrowseDealsFromCertifiedStores =>
      'Browse deals from certified stores and agencies';

  @override
  String get intentOnboardingWhatWillYouUseApolo =>
      'What will you\nuse Apolo for?';

  @override
  String get mainShellYouHaveNewApoloNotification =>
      'You have a new Apolo notification';

  @override
  String get mainShellBrowse => 'Browse';

  @override
  String get notificationsEnableNotifications => 'Enable notifications';

  @override
  String get notificationsAreBlocked => 'Notifications are blocked';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      'Please enable notifications in your phone or browser settings, then tap Continue again.';

  @override
  String get notificationsGotIt => 'Got it';

  @override
  String get notificationsNotificationPreferences => 'Notification preferences';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      'Choose which Apolo alerts you want to receive';

  @override
  String get notificationsMessagesBuyerOffers => 'Messages & buyer offers';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      'Instant alert when a buyer messages or makes an offer';

  @override
  String get notificationsPriceDropsSavedListings =>
      'Price drops & saved listings';

  @override
  String get notificationsUpdatesListingsYouBookmarked =>
      'Updates on listings you bookmarked';

  @override
  String get notificationsOfficialStoresUpdates => 'Official stores & updates';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'New arrivals from verified sellers you follow';

  @override
  String get notificationsMarkAllAsRead => 'Mark all as read';

  @override
  String get doneButton => 'Done';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      'Please allow notifications to continue';

  @override
  String get notificationsActivatedInstantAlerts =>
      ' activated instant alerts for ';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — Buyer Messages & Offers';

  @override
  String get notificationsJustNow => 'just now';

  @override
  String get notificationsApoloTeam => 'Apolo Team';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      ' shared a tip: Add clear photos to your listing to close deals faster.';

  @override
  String get notifications2hAgo => '2h ago';

  @override
  String get notificationsApoloOfficialStores => 'Apolo Official Stores';

  @override
  String get notificationsUpdated => ' updated ';

  @override
  String get notificationsVerifiedCarsRealEstateTech =>
      'Verified Cars, Real Estate & Tech Listings';

  @override
  String get notificationsAcrossAllMoroccanCities =>
      ' across all Moroccan cities.';

  @override
  String get notificationsThisWeek => 'This week';

  @override
  String get notificationsNotifications => 'Notifications';

  @override
  String get notificationsHeyItSApolo => 'Hey, it\'s Apolo!';

  @override
  String get notificationsIAmReadyHelpYou =>
      'I am ready to help you out. How about you?';

  @override
  String get notificationsNow => 'now';

  @override
  String get notificationsNotification => 'Notification';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'Activate notifications to receive messages';

  @override
  String get notificationsUpdates => 'Updates';

  @override
  String get notificationsNoNotificationsThisCategory =>
      'No notifications in this category';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      'Buyer messages, offers, and listing updates will appear here.';

  @override
  String get notificationsNoInternetConnection => 'No Internet connection';

  @override
  String get notificationsCheckWiFiMobileData =>
      'Check your Wi-Fi or mobile data to refresh your notifications.';

  @override
  String get notificationsToday => 'Today';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'Could not detect GPS location — pick your city';

  @override
  String get postAdPleaseSelectCategoryCity =>
      'Please select a category and city';

  @override
  String get postAdAddAtLeastOnePhoto =>
      'Add at least one photo for your listing';

  @override
  String get postAdEnterClearTitleAtLeast =>
      'Enter a clear title (at least 3 characters)';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      'Enter a valid price or Free and verify your phone number';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return 'Daily free limit reached ($maxDailyFreeAds ads/day)';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return 'Personal accounts include up to $maxDailyFreeAds free ads per day. Upgrade to Apolo Premium ($monthlyPremiumPriceMad MAD/mo via Google Pay) for unlimited daily ads, Business store, and Verified badge.';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return 'Subscribe ($monthlyPremiumPriceMad MAD/mo) • Google Pay';
  }

  @override
  String get postAdMaybeLater => 'Maybe later';

  @override
  String get postAdPleaseSignPublishListing =>
      'Please sign in to publish your listing';

  @override
  String get postAdAvailableGreatConditionApolo =>
      'Available in great condition on Apolo';

  @override
  String get postAdFailedPublishListing => 'Failed to publish your listing';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'Categories and cities unavailable. Retry';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium =>
      'Unlimited daily ads · Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return '$maxDailyFreeAds/$maxDailyFreeAds2 daily limit reached · Upgrade ($monthlyPremiumPriceMad MAD)';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return 'Today: $todayPostedAdsCount/$maxDailyFreeAds free ads · Unlimited with Premium';
  }

  @override
  String get postAdWhereAreYouListing => 'Where are you listing?';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      'Choose a category and city so nearby buyers can find it easily';

  @override
  String get postAdAddClearPhotos => 'Add clear photos';

  @override
  String get postAdListingsRealClearPhotosSell =>
      'Listings with real, clear photos sell up to 3x faster';

  @override
  String get postAdDescribeItem => 'Describe your item';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'A clear title and honest description build buyer trust';

  @override
  String get postAdSetPriceContact => 'Set price and contact';

  @override
  String get postAdSetFairPriceReviewListing =>
      'Set a fair price and review your listing before publishing';

  @override
  String get postAdGpsLocationSet => 'GPS location set';

  @override
  String get postAdDetectAdLocationGps => 'Detect ad location (GPS)';

  @override
  String get postAdTapAddPhotos => 'Tap to add photos';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return 'Add more photos ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed =>
      'The first photo will be used as the main cover';

  @override
  String get postAdGallery => 'Gallery';

  @override
  String get postAdSelectedPhotos => 'Selected photos';

  @override
  String get postAdCover => 'Cover';

  @override
  String get postAdListingTitle => 'Listing title';

  @override
  String get postAdGreat => 'Great ✓';

  @override
  String get postAdEGIphone15Pro => 'e.g. iPhone 15 Pro Max 256GB like new';

  @override
  String get postAdDetailedDescription => 'Detailed description';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      'Mention condition, included accessories, and key details...';

  @override
  String get postAdSpecifications => 'Specifications';

  @override
  String get postAdPriceMad => 'Price (MAD)';

  @override
  String get postAdEG2500 => 'e.g. 2500';

  @override
  String get postAdHideNumber => 'Hide number';

  @override
  String get postAdListingPreview => 'Listing preview';

  @override
  String get postAdPublishNow => 'Publish now';

  @override
  String get postAdListingUpdated => 'Listing updated';

  @override
  String get postAdListingIsLive => 'Your listing is live';

  @override
  String get postAdListingIsNowVisibleBuyers =>
      'Your listing is now visible to buyers across Apolo.ma.';

  @override
  String get postAdNewListing => 'Your new listing';

  @override
  String get postAdBackHome => 'Back to home';

  @override
  String get postAdPostAnotherListing => 'Post another listing';

  @override
  String get privacyComplianceReportAiPolicyIssue =>
      'Report AI or Policy Issue';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      'Select a reason to submit this report for immediate Trust & Safety review:';

  @override
  String get privacyComplianceAdditionalDetailsOptional =>
      'Additional details (optional)...';

  @override
  String get privacyComplianceSubmitReport => 'Submit report';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      'Could not send report. Please try again.';

  @override
  String get privacyComplianceReportSubmittedSuccessfully =>
      'Report submitted successfully ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'Link copied: $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion =>
      'Confirm account deletion';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      'Are you sure you want to permanently delete your account, personal data, listings, and messages from Apolo? This cannot be undone.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get privacyComplianceDeletePermanently => 'Delete permanently';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted =>
      'Your account and data have been deleted.';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      'Could not confirm deletion. You remain signed in. Please try again.';

  @override
  String get privacyCompliancePrivacyPolicies => 'Privacy & Policies';

  @override
  String get privacyCompliancePrivacy => 'Privacy';

  @override
  String get privacyCompliancePolicies => 'Policies';

  @override
  String get privacyComplianceDataDelete => 'Data & Delete';

  @override
  String get privacyComplianceUpdated2026Law0908 =>
      'Updated 2026 · Law 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl =>
      'Your privacy, fully in your control';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      'We never sell your personal data. Information is used strictly to power your listings, secure chats, and mobile notifications on Apolo (ma.apolo.apoloMobile).';

  @override
  String get privacyComplianceDataWeCollect => 'Data We Collect';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• Account identity: Name, email, phone number, or secure Google / Apple sign-in.\n• Listings & stores: Photos, titles, descriptions, MAD prices, and selected city.\n• Real-time messaging: Chat messages, media, and emoji reactions between buyers and sellers.\n• Mobile push tokens (FCM / APNs): Used solely to deliver OS notifications and automatically deactivated on sign-out.';

  @override
  String get privacyComplianceDevicePermissionsControls =>
      'Device Permissions & Controls';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• Notifications: Optional OS alerts for new messages on iOS & Android; adjustable anytime.\n• Camera & Photos: Requested only when you upload listing photos or chat attachments.\n• Approximate zone: City-level distance filtering with zero background GPS tracking.';

  @override
  String get privacyComplianceAiSafetyAppReporting =>
      'AI Safety & In-App Reporting';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'Smart listing and search tools include direct in-app reporting so you can flag inaccurate AI suggestions or abusive listings immediately.';

  @override
  String get privacyComplianceLegalRightsContact =>
      'Your Legal Rights & Contact';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'Under Moroccan Law 09-08 and App Store / Google Play rules, you have the right to access, update, or permanently erase your personal data.\n• Official email: support@apolo.ma / contact@apolo.ma\n• Website: https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp =>
      'Report AI or Policy Issue In-App';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy => 'Open Web Privacy Policy';

  @override
  String get privacyComplianceTermsUseMarketplaceRules =>
      'Terms of Use & Marketplace Rules';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      'Clear rules for safe buying & selling';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'By using Apolo, you agree to authentic listings, respectful messaging, and transparent marketplace rules.';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'Account Integrity & Verified Badges';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• Account and store details must remain accurate and truthful.\n• Verified seals and seller ranks (Bronze to Champion) are awarded strictly by Apolo; impersonation is prohibited.';

  @override
  String get privacyComplianceListingRulesProhibitedItems =>
      'Listing Rules & Prohibited Items';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• Listings must represent real items or services with genuine photos and honest pricing.\n• Strictly prohibited: counterfeit goods, weapons, illegal substances, prescription drugs, stolen goods, and advance-fee scams.';

  @override
  String get privacyComplianceSafeTransactionsChatConduct =>
      'Safe Transactions & Chat Conduct';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• Always inspect items in person in a safe public place and avoid sending advance deposits.\n• Spam, harassment, and abusive messages result in immediate suspension; block or report anytime.';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'Pro+ Subscriptions & Listing Boosts';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• Pro+ plans and Boost upgrades are billed transparently through your App Store or Google Play account.\n• Cancel auto-renewal anytime at least 24 hours before period end in your store account settings.';

  @override
  String get privacyComplianceOpenWebTermsPolicies =>
      'Open Web Terms & Policies';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      'Instant Erasure · App Store & Play';

  @override
  String get privacyCompliancePermanentAccountDataDeletion =>
      'Permanent Account & Data Deletion';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'Erase your account and all associated personal data directly in-app or via our external web deletion form.';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted =>
      'What Gets Permanently Deleted';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• Profile credentials (name, email, phone number, and OAuth links).\n• All published listings, uploaded photos, and store data.\n• Chat history, saved favorites, and active mobile push notification tokens.';

  @override
  String get privacyComplianceDeleteMyAccountNowApp =>
      'Delete My Account Now (In-App)';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'Sign in to delete your account directly in-app, or use the external web link below.';

  @override
  String get privacyComplianceExternalWebDataDeletionLink =>
      'External Web Data Deletion Link';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      'Recurring billing. Cancel anytime. Payment will be charged to your Google Pay / Store account at confirmation of purchase and automatically renews unless turned off at least 24 hours before the end of the current period.\nAll personal data is handled under the ';

  @override
  String get proPlusTermsConditions => 'terms and conditions';

  @override
  String get proPlusAnd => ' and ';

  @override
  String get proPlusPrivacyPolicy => 'privacy policy';

  @override
  String get proPlusSubscription => 'Subscription';

  @override
  String get proPlusCancelPremiumSubscription =>
      'Cancel your Premium subscription?';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'Auto-renewal will be turned off while keeping your store and listings safe.';

  @override
  String get proPlusCancelMySubscription => 'Cancel my subscription';

  @override
  String get proPlusKeepPremium => 'Keep Premium';

  @override
  String get proPlusYouUsePremium => 'You use Premium';

  @override
  String get proPlusGetPremium => 'Get Premium';

  @override
  String get proPlusYouHaveUnlimitedAccessAll =>
      'You have unlimited access to all premium features';

  @override
  String get proPlusGetUnlimitedAccessAllPremium =>
      'Get unlimited access to all premium features';

  @override
  String get proPlusCheckedAccountActivePurchases =>
      'Checked your account for active purchases.';

  @override
  String get proPlusHowTrialWorks => 'How your trial works';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return 'Unlimited free access for 3 days, then only $monthlyPremiumPriceMad MAD/month via Google Pay';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      'Get instant access and see how Pro Plus transforms your sales.';

  @override
  String get proPlusDay2 => 'Day 2';

  @override
  String get proPlusWeLlRemindYouNotification =>
      'We\'ll remind you with a notification that your trial is ending.';

  @override
  String get proPlusDay3 => 'Day 3';

  @override
  String get proPlusYouLlBeChargedDay =>
      'You\'ll be charged on Day 3, cancel anytime before.';

  @override
  String get proPlusViewAllPlans => 'View all plans';

  @override
  String get proPlusRestorePurchases => 'Restore purchases';

  @override
  String get proPlusStartFree3DayTrial => 'Start free 3-day trial';

  @override
  String get proPlusPaymentVerificationFailed => 'Payment verification failed.';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      'Pro Plus activated! Your store is now verified';

  @override
  String get proPlusCouldNotLaunchGooglePay =>
      'Could not launch Google Pay on this device.';

  @override
  String get proPlusPayGooglePay => 'Pay with Google Pay';

  @override
  String get proPlusSave25 => 'Save 25%';

  @override
  String get proPlusLifetime => 'Lifetime';

  @override
  String get proPlusBasic => 'Basic';

  @override
  String get proPlus12Months => '12 months';

  @override
  String get proPlusOneTime => 'One-time';

  @override
  String get proPlus1Month => '1 month';

  @override
  String get proPlusMad => 'MAD';

  @override
  String get proPlusPaywall => 'Paywall';

  @override
  String get proPlusUnlockFullAccess => 'Unlock full access';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'Unlimited access to all features and templates';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      'Official Business store + blue Verified badge';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      'Unlimited daily listings (instead of 5/day) + 12 photos';

  @override
  String get proPlus5FreeMonthlyVipBoosts =>
      '5 free monthly VIP boosts + Pro Insights & quick replies';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return 'Subscribe for $priceDisplay MAD • Google Pay';
  }

  @override
  String get proPlusNoThankYou => 'No, thank you';

  @override
  String get profileCouldNotLoadListingsPull =>
      'Could not load listings. Pull to retry.';

  @override
  String get profileMyAccount => 'My account';

  @override
  String get profileSettingsSupport => 'Settings & support';

  @override
  String get profileSignManageListingsSavedItems =>
      'Sign in to manage your listings, saved items, and instant chats.';

  @override
  String get profileSignViewProfile => 'Sign in to view your profile';

  @override
  String get welcomeCreateAccountButton => 'Create an account';

  @override
  String get profileLightMode => 'Light mode';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get profileListings => 'Listings';

  @override
  String get profileLikes => 'Likes';

  @override
  String get profileSaved => 'Saved';

  @override
  String get shareProfileButton => 'Share profile';

  @override
  String get profileMyListings => 'My Listings';

  @override
  String get profileProInsightsBoost => 'Pro Insights & Boost';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'Upgrade to Apolo Premium · $monthlyPremiumPriceMad MAD/mo';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'Business store + Verified badge + unlimited daily ads via Google Pay.';

  @override
  String get profileViewStore => 'View store';

  @override
  String get profileEditStore => 'Edit store';

  @override
  String get profileQuickReplies => 'Quick replies';

  @override
  String get profileNoListingsYet => 'No listings yet';

  @override
  String get profilePublishFirstListingShowcaseIt =>
      'Publish your first listing to showcase it here.';

  @override
  String get profilePostListing => 'Post a listing';

  @override
  String get profileTotalViews => 'Total views';

  @override
  String get profileActiveListings => 'Active listings';

  @override
  String get profileAvgListing => 'Avg. / listing';

  @override
  String get profileBoostedListings => 'Boosted listings';

  @override
  String get profileCallTaps => 'Call taps';

  @override
  String get profileCustomerChats => 'Customer chats';

  @override
  String get profileDirectOrders => 'Direct orders';

  @override
  String get profileFreeVipCredits => 'Free VIP credits';

  @override
  String get profileUnlockCallOrderStatsPro =>
      'Unlock call & order stats + PRO+ Badge';

  @override
  String get profileGet3FreeVipBoosts =>
      'Get 3 free VIP boosts/month and priority visibility.';

  @override
  String get profileViewsBreakdown => 'Views breakdown';

  @override
  String get profileLive => 'Live';

  @override
  String get profilePublishFirstListingTrackViews =>
      'Publish your first listing to track views and performance here.';

  @override
  String get profileTopPerformingListings => 'Top performing listings';

  @override
  String get profileViews => 'views';

  @override
  String get profileSalesTip => 'Sales tip';

  @override
  String get profileAddClearPhotosFairPrice =>
      'Add clear photos and a fair price on your first listing to attract buyers fast.';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      'Refreshing photos or boosting your top listing helps it sell faster.';

  @override
  String get profileEditListing => 'Edit listing';

  @override
  String get profileBoostThisListing => 'Boost this listing';

  @override
  String get profileDeleteListing => 'Delete listing';

  @override
  String get profileCouldNotDeleteListingPlease =>
      'Could not delete listing. Please try again.';

  @override
  String get profileDeleteThisListing => 'Delete this listing?';

  @override
  String get profileThisListingWillBePermanently =>
      'This listing will be permanently removed from your profile and search results.';

  @override
  String get profileListingDeletedSuccessfully =>
      'Listing deleted successfully';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'This is your own profile';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'Apolo Member #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => 'Scanned Code';

  @override
  String get scanProfileCodeCodeDetected => 'Code Detected';

  @override
  String get scanProfileCodeOpenLink => 'Open link';

  @override
  String get scanProfileCodeScanAgain => 'Scan again';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'Flashlight is unavailable in this browser';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'Flashlight is unavailable on this camera';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight =>
      'Could not toggle flashlight right now';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      'No QR code detected in the selected image';

  @override
  String get scanProfileCodeEnterCode => 'Enter code';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary =>
      'Could not open photo library';

  @override
  String get scanProfileCodeScanQrCode => 'Scan QR code';

  @override
  String get scanProfileCodePickQrImage => 'Pick QR image';

  @override
  String get scanProfileCodeTapEnableCamera => 'Tap to enable camera';

  @override
  String get scanProfileCodeEnterCodeManually => 'Enter code manually';

  @override
  String get scanProfileCodePleaseEnterLinkHandle =>
      'Please enter a link or handle';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'Paste an Apolo profile link or enter @handle';

  @override
  String get scanProfileCodeOpenProfile => 'Open profile';

  @override
  String get searchRecommended => 'Recommended';

  @override
  String get searchNewest => 'Newest';

  @override
  String get searchLowestPrice => 'Lowest price';

  @override
  String get searchHighestPrice => 'Highest price';

  @override
  String get searchMostViewed => 'Most viewed';

  @override
  String get searchFilterSort => 'Filter & Sort';

  @override
  String get resetButton => 'Reset';

  @override
  String get searchSortBy => 'Sort by';

  @override
  String get searchAllMorocco => 'All Morocco';

  @override
  String get searchPriceRangeMad => 'Price range (MAD)';

  @override
  String get searchMinPrice => 'Min price';

  @override
  String get searchMaxPrice => 'Max price';

  @override
  String get searchNegotiableListingsOnly => 'Negotiable listings only';

  @override
  String get searchApplyFilters => 'Apply filters';

  @override
  String get searchSignSaveSearchesListings =>
      'Sign in to save searches & listings';

  @override
  String get searchSaved => 'Search saved';

  @override
  String get searchUnableSaveSearchRightNow =>
      'Unable to save search right now';

  @override
  String get searchSaveSearch => 'Save search';

  @override
  String get searchNoSavedListingsYet => 'No saved listings yet';

  @override
  String get searchTapHeartAnyListingSave =>
      'Tap the heart on any listing to save it here';

  @override
  String get searchFilter => 'Filter';

  @override
  String get searchAllCategories => 'All categories';

  @override
  String get searchAllAreas => 'All areas';

  @override
  String get searchSetArea => 'Set area';

  @override
  String get searchFeedView => 'Feed view';

  @override
  String get searchGridView => 'Grid view';

  @override
  String get personalAccountBadge => 'Personal';

  @override
  String get businessAccountBadge => 'Business';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'No listings within $zoneRadiusKm km of $s.';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      'Try another category or broaden your filters.';

  @override
  String get searchResetFilters => 'Reset filters';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable =>
      'Seller phone number not available';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      'Select a listing to message this seller.';

  @override
  String get sellerProfileReportSeller => 'Report seller';

  @override
  String get sellerProfileBlockSeller => 'Block seller';

  @override
  String get sellerProfileSellerBlockedSuccessfully =>
      'Seller blocked successfully';

  @override
  String get sellerProfileFollowers => 'Followers';

  @override
  String get sellerProfileRating => 'Rating';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return 'Individual seller in $city · Direct chat reply.';
  }

  @override
  String get sellerProfileVisitStore => 'Visit store';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return 'Listings ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return 'Reviews ($count)';
  }

  @override
  String get sellerProfileTrustInfo => 'Trust & Info';

  @override
  String get sellerProfileNoListingsAvailableRightNow =>
      'No listings available right now';

  @override
  String get sellerProfile3DaysAgo => '3 days ago';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'Very reliable seller, item matched the photos and great communication throughout.';

  @override
  String get sellerProfile1WeekAgo => '1 week ago';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      'Smooth buying experience, inspected before payment. Highly recommended!';

  @override
  String get sellerProfile2WeeksAgo => '2 weeks ago';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      'Honest and respectful seller. Let me inspect the laptop thoroughly.';

  @override
  String get sellerProfile1MonthAgo => '1 month ago';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      'Great transaction with full trust. Fast replies on Apolo chat.';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '$count verified reviews';
  }

  @override
  String get sellerProfileGovernmentIdVerified => 'Government ID Verified';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'Official identity document reviewed and verified by Apolo Trust Team.';

  @override
  String get sellerProfileVerifiedPhoneNumber => 'Verified Phone Number';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'Phone number confirmed via SMS OTP verification.';

  @override
  String get sellerProfileApoloSafetyProtection => 'Apolo Safety Protection';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'We recommend inspecting the item in person before making any payment.';

  @override
  String get sellerProfileAvailableDeliveryMethods =>
      'Available Delivery Methods';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return 'Hand-to-hand pickup in $city, or insured express shipping by agreement.';
  }

  @override
  String get accountCenterSwitchPersonalAccount => 'Switch to Personal Account';

  @override
  String get accountCenterReturnPersonalAccount =>
      'Return to a personal account?';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'Your business store page will be paused. You can re-enable it anytime.';

  @override
  String get accountCenterConfirmSwitch => 'Confirm switch';

  @override
  String get accountCenterSwitchedPersonalAccount =>
      'Switched to Personal Account.';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'Could not switch account type. Please try again.';

  @override
  String get accountCenterApoloAccount => 'Apolo Account';

  @override
  String get accountCenterPersonalDetails => 'Personal details';

  @override
  String get accountCenterEmailPhone => 'Email & phone';

  @override
  String get accountCenterAccountTypePreferences =>
      'Account type & preferences';

  @override
  String get accountCenterPasswordSecurity => 'Password & security';

  @override
  String get accountCenterResetPassword => 'Reset password';

  @override
  String get accountCenterBusinessStore => 'Business & Store';

  @override
  String get accountCenterEditStoreProfile => 'Edit Store Profile';

  @override
  String get accountCenterSwitchBusinessAccount => 'Switch to Business Account';

  @override
  String get accountCenterAccountOwnership => 'Account ownership';

  @override
  String get accountCenterDeleteAccountData => 'Delete account & data';

  @override
  String get accountCenterManageApoloAccount => 'Manage your Apolo Account';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'Sign in to manage security, personal details, and your store.';

  @override
  String get logInButton => 'Log in';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully =>
      'App data refreshed successfully.';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'Could not refresh data. Check your connection and try again.';

  @override
  String get settingsAppDataAppDataSync => 'App data & sync';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'System information and local sync status with Apolo.ma.';

  @override
  String get settingsAppDataApplicationStatus => 'Application status';

  @override
  String get settingsAppDataAppVersion => 'App version';

  @override
  String get settingsAppDataServer => 'Server';

  @override
  String get settingsAppDataSyncedCategories => 'Synced categories';

  @override
  String get settingsAppDataSyncedCities => 'Synced cities';

  @override
  String get settingsAppDataActiveZone => 'Active zone';

  @override
  String get settingsAppDataOpenSourceLicenses => 'Open-source licenses';

  @override
  String get settingsAppDataRefreshDataNow => 'Refresh data now';

  @override
  String get settingsAppearanceAppearance => 'Appearance';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'Choose how Apolo looks. Switch between Light mode, Dark mode, or match your device settings automatically.';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      'Clean white surfaces and crisp daylight contrast';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      'Easy on the eyes in low light and saves battery';

  @override
  String get settingsAppearanceSystemDefault => 'System default';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'Automatically matches your phone or browser theme';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return 'Unblocked $name';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'Blocked accounts';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet =>
      'No blocked accounts yet';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'Users or stores you block from chats or listings will appear here so you can unblock them anytime.';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser =>
      'You can unblock any user or store anytime.';

  @override
  String get settingsBlockedAccountsBlockedStore => 'Blocked store';

  @override
  String get settingsBlockedAccountsBlockedUser => 'Blocked user';

  @override
  String get settingsBugReportQuickTrigger => 'Quick trigger';

  @override
  String get settingsBugReportDiagnosticsSummary => 'Diagnostics summary';

  @override
  String get settingsBugReportPlatform => 'Platform';

  @override
  String get settingsBugReportActiveLanguage => 'Active language';

  @override
  String get settingsBugReportHelpSupport => 'Help & Support';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      'Could not save language. Please try again.';

  @override
  String get settingsLanguageAppLanguage => 'App language';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'Choose the language for the app interface and listings. Changes apply immediately across the app.';

  @override
  String get settingsRateAppNeedsWork => 'Needs work';

  @override
  String get settingsRateAppFair => 'Fair';

  @override
  String get settingsRateAppGreat => 'Great';

  @override
  String get settingsRateAppAwesome => 'Awesome!';

  @override
  String get settingsRateAppSelectStars => 'Select stars';

  @override
  String get settingsRateAppPleaseSelect15Stars =>
      'Please select 1 to 5 stars.';

  @override
  String get settingsRateAppRateApp => 'Rate App';

  @override
  String get settingsRateAppHowIsExperienceApoloMa =>
      'How is your experience with Apolo.ma?';

  @override
  String get settingsRateAppAddQuickNoteOptional =>
      'Add a quick note (optional)...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return 'Thank you for rating us $rating/5!';
  }

  @override
  String get settingsRateAppSubmitRating => 'Submit rating';

  @override
  String get settingsRateAppVisitApoloMa => 'Visit Apolo.ma';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'Could not remove saved listing. Please try again.';

  @override
  String get settingsSavedAdsSignViewSavedListings =>
      'Sign in to view saved listings';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      'Save listings you like to revisit them anytime.';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings =>
      'Could not load saved listings';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'Check your internet connection and try again.';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      'Tap the favorite icon on any listing to save it here.';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'Check out Apolo.ma — Morocco’s classifieds & stores marketplace: $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'Share App';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      'Morocco’s marketplace for classifieds and official stores. Share with friends and family.';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'App link copied: $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => 'Share now';

  @override
  String get settingsShareAppCopyLink => 'Copy link';

  @override
  String get settingsShareAppShareMyQrProfile => 'Share my QR profile';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'Please enter a suggestion of at least 5 characters.';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      'Could not send over the network right now. Try again or send via email.';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'Copied support@apolo.ma';

  @override
  String get settingsSuggestionFeature => 'Feature';

  @override
  String get settingsSuggestionDesign => 'Design';

  @override
  String get settingsSuggestionPerformance => 'Performance';

  @override
  String get settingsSuggestionOther => 'Other';

  @override
  String get settingsSuggestionMakeSuggestion => 'Make a suggestion';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'Share your ideas to help us improve Apolo.ma.';

  @override
  String get settingsSuggestionTopic => 'Topic';

  @override
  String get settingsSuggestionYourSuggestion => 'Your suggestion';

  @override
  String get settingsSuggestionWriteIdeaHere => 'Write your idea here...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      'Thank you! Your suggestion has been received.';

  @override
  String get settingsSuggestionSubmitSuggestion => 'Submit suggestion';

  @override
  String get settingsSuggestionEmailSupportApoloMa => 'Email support@apolo.ma';

  @override
  String get settingsZoneMarketplaceZone => 'Marketplace Zone';

  @override
  String get logOutButton => 'Log out';

  @override
  String get settingsLogOutAccount => 'Log out of your account?';

  @override
  String get settingsYouCanSignBackAnytime =>
      'You can sign back in anytime to access your listings and messages.';

  @override
  String get settingsProActive => 'PRO+ Active';

  @override
  String get settingsNotSubscribed => 'Not subscribed';

  @override
  String get settingsVipBoostCredits => 'VIP Boost Credits';

  @override
  String get settingsPrivacyTerms => 'Privacy & Terms';

  @override
  String get settingsAppDataLicenses => 'App data & licenses';

  @override
  String get settingsActivity => 'Settings and activity';

  @override
  String get settingsNoMatchingSettings => 'No matching settings';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      'Try another keyword such as Saved, Language, or Pro+.';

  @override
  String get settingsYourAccount => 'Your account';

  @override
  String get settingsHowYouUseApolo => 'How you use Apolo';

  @override
  String get settingsSubscriptions => 'Subscriptions';

  @override
  String get settingsCommunityPrivacy => 'Community & Privacy';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'Password, security, personal details, store & business';

  @override
  String get shareProfileProfileLinkCopied => 'Profile link copied';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'Check out $name ($handle) on Apolo.ma:\n$url';
  }

  @override
  String get shareProfileShareLink => 'Share link';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'Your QR code is private. If you share it with someone, that person can scan it with their camera to add you as a contact.';

  @override
  String get shareProfileScanCode => 'Scan code';

  @override
  String get storeDetailReportStore => 'Report store';

  @override
  String get storeDetailStoreBlocked => 'Store blocked';

  @override
  String get storeDetailBlockStore => 'Block store';

  @override
  String get storeDetailDirectStoreOrder => 'Direct Store Order';

  @override
  String get storeDetailSelectItem => 'Select item';

  @override
  String get storeDetailFullName => 'Full name';

  @override
  String get storeDetailDeliveryAddress => 'Delivery address';

  @override
  String get storeDetailOrderNotes => 'Order notes';

  @override
  String get storeDetailConfirmOrder => 'Confirm order';

  @override
  String get storeDetailOrderSubmittedSuccessfully =>
      'Order submitted successfully';

  @override
  String get storeDetailStoreNotFound => 'Store not found';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'Check the link or browse verified stores.';

  @override
  String get storeDetailOrderNow => 'Order now';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return 'Open · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return 'Closed · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'Open in Google Maps';

  @override
  String get storeDetailOrder => 'Order';

  @override
  String get storeDetailProducts => 'Products';

  @override
  String get verifiedBadgeLabel => 'Verified';

  @override
  String get storeDetailDelivery => 'Delivery';

  @override
  String get storeDetailStoreCatalog => 'Store Catalog';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '$totalStores verified official stores';
  }

  @override
  String get storesSearchOfficialStores => 'Search official stores...';

  @override
  String get storesMostProducts => 'Most products';

  @override
  String get storesTopRated => 'Top rated';

  @override
  String get storesNoMatchingStores => 'No matching stores';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      'Try another keyword or reload the verified stores list.';

  @override
  String get storesItems => 'items';

  @override
  String get storesVisit => 'Visit';

  @override
  String get supportCouldNotOpenMailApp =>
      'Could not open your mail app. Please email support@apolo.ma manually.';

  @override
  String get supportHowCanWeHelpYou => 'How can we help you?';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      'Explain the issue and the steps before it. You may attach a screenshot after masking personal details.';

  @override
  String get supportDirectContact => 'Direct contact';

  @override
  String get supportOpenMailApp => 'Open Mail App';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'No email is sent automatically. Review and send it from your mail app.';

  @override
  String get supportSafetyReminder => 'Safety reminder';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'Never share your password, verification code, or payment details with anyone.';

  @override
  String get welcomeUnableStartGoogleSignRight =>
      'Unable to start Google sign-in right now.';

  @override
  String get welcomeContinueGoogle => 'Continue with Google';

  @override
  String get welcomeOr => 'or';

  @override
  String get welcomeIHaveAccount => 'I have an account';

  @override
  String get welcomeNewOfferReceivedListing =>
      'New offer received on your listing!';

  @override
  String get welcomeY => 'Y';

  @override
  String get welcomeYassineCasablanca => 'Yassine • Casablanca';

  @override
  String get welcomeYesAvailableWelcome => 'Yes available, welcome!';

  @override
  String get accommodationCardSintraPortugal => 'Sintra, Portugal';

  @override
  String get accommodationCardExclusiveDeal => 'Exclusive deal';

  @override
  String get adCardVip => 'VIP';

  @override
  String get safetyReportMessage => 'Report message';

  @override
  String get safetyReportListing => 'Report listing';

  @override
  String get safetyReportUser => 'Report user';

  @override
  String get safetyAlsoBlockThisAccount => 'Also block this account';

  @override
  String get safetySubmitReport => 'Submit Report';

  @override
  String get safetyReportSubmittedSuccessfully =>
      'Report submitted successfully';

  @override
  String get safetyBlockedAccounts => 'Blocked Accounts';

  @override
  String get boostCouldNotCompletePayment => 'Could not complete payment';

  @override
  String get boostListingBoosted => 'Listing boosted!';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'Payment not confirmed. Contact support before retrying.';

  @override
  String get boostVipBoostActivatedUsingPro =>
      'VIP Boost activated using your Pro+ credit!';

  @override
  String get boostListing => 'Boost your listing';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'Activate free VIP with Pro+ ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts =>
      'Get 3 free VIP boosts/month with Apolo Pro+';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      'Plans are currently unavailable. Please try again later.';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'Instant web checkout is enabled for your account.';

  @override
  String get boostActivateBoostNow => 'Activate Boost now';

  @override
  String get chatUtilsYesterday => 'Yesterday';

  @override
  String get guestFavoriteBadge => 'Guest favorite';

  @override
  String get exploreListingCardContactSeller => 'Contact seller';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      'Could not auto-detect location — select your city below';

  @override
  String get marketplaceZoneMarketplaceLocation => 'Marketplace Location';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal =>
      'Only see listings inside your local area';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress =>
      'Search neighborhood, city, address...';

  @override
  String get marketplaceZoneNationwide => 'Nationwide';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically =>
      'Detect my location automatically';

  @override
  String get marketplaceZoneDistanceRadius => 'Distance radius';

  @override
  String get marketplaceZoneAllMorocco => 'All of Morocco';

  @override
  String get marketplaceZoneSelectCity => 'Select city';

  @override
  String get marketplaceZoneApplyZone => 'Apply zone';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return 'Limit reached ($maxAllowed). Upgrade to Pro Plus for more!';
  }

  @override
  String get quickRepliesQuickRepliesSaved => 'Quick replies saved ⚡';

  @override
  String get quickRepliesChatQuickReplies => 'Chat Quick Replies';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'Tap any shortcut inside Chat to reply to buyers in one tap.';

  @override
  String get quickRepliesAddQuickReply => 'Add quick reply';

  @override
  String get quickRepliesLabel => 'Label';

  @override
  String get quickRepliesReplyText => 'Reply text...';

  @override
  String get quickRepliesAutoGreetingMessage => 'Auto-greeting message';

  @override
  String get quickRepliesWelcomeStore => 'Welcome to our store!';

  @override
  String get quickRepliesSaveQuickReplies => 'Save Quick Replies';

  @override
  String get quickRepliesManage => 'Manage';

  @override
  String get realMarketplaceMapApproximateMapArea => 'Approximate map area';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return '$distKm km from you';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'Set as my zone';

  @override
  String get badgesKitBronze => 'Bronze';

  @override
  String get badgesKitSilver => 'Silver';

  @override
  String get badgesKitGold => 'Gold';

  @override
  String get badgesKitPlatinum => 'Platinum';

  @override
  String get badgesKitDiamond => 'Diamond';

  @override
  String get badgesKitChampion => 'Champion';

  @override
  String get badgesKitStarterMemberApolo => 'Starter member on Apolo';

  @override
  String get badgesKitVerifiedAccount2Listings =>
      'Verified account or 2+ listings';

  @override
  String get badgesKitBusinessStore5Listings => 'Business store or 5+ listings';

  @override
  String get badgesKitActiveProActiveStore8 =>
      'Active Pro+ or active store (8+)';

  @override
  String get badgesKitPro10Listings1500 =>
      'Pro+ with 10+ listings or 1,500 views';

  @override
  String get badgesKitTopTierPro20Listings =>
      'Top tier: Pro+ with 20+ listings or 5,000 views';

  @override
  String get badgesKitSellerRank => 'Seller rank:';

  @override
  String get badgesKitTopRankUnlockedApolo => 'Top rank unlocked on Apolo!';

  @override
  String get badgesKitNext => 'Next:';

  @override
  String get badgesKitTrustSellerRanks => 'Trust & Seller Ranks';

  @override
  String get badgesKitCurrentRank => 'Current rank:';

  @override
  String get badgesKitVerifiedApoloAccount => 'Verified Apolo Account';

  @override
  String get badgesKitVerifiedSeal => 'Verified Seal';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      'Identity and contact details verified for safer transactions.';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      'Earned by verifying your phone number or activating a Pro store.';

  @override
  String get badgesKitAllSellerRanks => 'All Seller Ranks';

  @override
  String get badgesKitCurrent => 'Current';

  @override
  String get infeedUpgradeCardYourProfile => 'your_profile';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'Build credibility with buyers when you subscribe to Apolo Premium.';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'Upgrade your profile';

  @override
  String get infeedUpgradeCardNotNow => 'Not now';

  @override
  String get searchSuggestionsSearchUsernames => 'Search for usernames';

  @override
  String get searchSuggestionsSuggestions => 'Suggestions';

  @override
  String get searchSuggestionsRecentSearches => 'Recent searches';

  @override
  String get searchSuggestionsPopularSearches => 'Popular searches';

  @override
  String get followedButton => 'Followed';

  @override
  String get writeReviewExcellent => 'Excellent';

  @override
  String get writeReviewVeryGood => 'Very good';

  @override
  String get writeReviewPoor => 'Poor';

  @override
  String get writeReviewGreatCommunication => 'Great communication';

  @override
  String get writeReviewAsDescribed => 'As described';

  @override
  String get writeReviewFastResponse => 'Fast response';

  @override
  String get writeReviewFairPrice => 'Fair price';

  @override
  String get writeReviewReviewHasBeenPosted => 'Your review has been posted';

  @override
  String get writeReviewShareExperienceThisSeller =>
      'Share your experience with this seller...';

  @override
  String get writeReviewUpdateReview => 'Update review';

  @override
  String get writeReviewSubmitReview => 'Submit review';

  @override
  String get interestsSurveyWhatAreInterests => 'What are your interests?';

  @override
  String get interestsSurveyDiscoverProducts => 'Discover products';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return 'Save & continue ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => 'Skip for now';

  @override
  String get priceLabel => 'Price';

  @override
  String get conditionLabel => 'Condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionLikeNew => 'Like New';

  @override
  String get conditionUsed => 'Used';

  @override
  String get fulfillmentMeetInPerson => 'Meet in person';

  @override
  String get fulfillmentDelivery => 'Delivery';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusReserved => 'Reserved';

  @override
  String get safetyTipsTitle => 'Safety tips';
}
