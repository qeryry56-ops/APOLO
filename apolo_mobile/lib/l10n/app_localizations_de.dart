// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get chatPlaceholder => 'Verkäufer schreiben...';

  @override
  String get chatTypeMessageHint => 'Nachricht schreiben...';

  @override
  String get chatRecordingPlaceholder => 'Aufnahme...';

  @override
  String get chatAddAttachmentTooltip => 'Anhang hinzufügen';

  @override
  String get chatMessageInputLabel => 'Nachrichteneingabe';

  @override
  String get chatSendMessageTooltip => 'Nachricht senden';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return 'Ausgewählter Anhang: $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return 'Anhang $name entfernen';
  }

  @override
  String get chatDismissMessageMenu => 'Nachrichtenmenü schließen';

  @override
  String get chatJumpToLatest => 'Nach unten';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count neue $messageWord. Nach unten';
  }

  @override
  String get chatMessageSingular => 'Nachricht';

  @override
  String get chatMessagePlural => 'Nachrichten';

  @override
  String get chatCallAndOptionsTooltip => 'Anruf- und Chat-Optionen';

  @override
  String get chatSendFailedRetrySemantic =>
      ', Senden fehlgeschlagen, zum Wiederholen doppeltippen';

  @override
  String get chatSendingSemantic => ', Wird gesendet';

  @override
  String get chatEditedLabel => 'Bearbeitet';

  @override
  String get chatRetrySendingTooltip => 'Erneut senden';

  @override
  String get chatTypingIndicatorLabel => 'Schreibt...';

  @override
  String get chatPhotoPreviewLabel => '📷 Foto';

  @override
  String get chatVoicePreviewLabel => '🎤 Sprachnachricht';

  @override
  String get voiceMicMutedIdleSemantic =>
      'Mikro stumm. Kein Ton erkannt. Mikro-Taste halten für Sprachnachricht';

  @override
  String get voiceHoldToRecordSemantic =>
      'Halten für Sprachnachricht. Nach links wischen zum Abbrechen, nach oben zum Sperren';

  @override
  String get voiceMicMutedSuffixSemantic =>
      '. Warnung: Mikro stumm, kein Ton erkannt';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return 'Loslassen zum Abbrechen der Aufnahme$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Freihand-Aufnahme aktiv, $timeStr$mutedSuffix. Tippe auf STOP zum Beenden';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Sprachnachricht wird aufgenommen, $timeStr$mutedSuffix. Nach links zum Abbrechen, nach oben zum Sperren';
  }

  @override
  String get voiceWaveformMutedSemantic => 'Flache Wellenform, Mikro stumm';

  @override
  String get voiceWaveformPreviewSemantic => 'Interaktive Audio-Vorschau';

  @override
  String get voiceWaveformLiveSemantic => 'Live-Audiowellenform';

  @override
  String get voiceMicMutedWarningSemantic =>
      'Warnung: Mikro stumm. Kein Ton erkannt.';

  @override
  String get voiceMicMutedBadge => 'Mikro stumm';

  @override
  String get voiceCancelRecordingTooltip => 'Aufnahme abbrechen';

  @override
  String get voicePauseRecordingTooltip => 'Aufnahme oder Vorschau pausieren';

  @override
  String get voicePlayPreviewTooltip => 'Vorschau abspielen';

  @override
  String get voiceSendVoiceMessageTooltip => 'Sprachnachricht senden';

  @override
  String get voiceReleaseToCancelLabel => 'Loslassen: Abbruch';

  @override
  String get voiceSlideToCancelLabel => 'Wischen: Abbruch';

  @override
  String get voiceHoldMicPrompt => 'Mikro halten für Sprachnachricht';

  @override
  String get voiceRecordButtonSemantic => 'Sprachnachricht aufnehmen';

  @override
  String get voiceRecordGestureHint =>
      'Tippen oder halten zum Aufnehmen. Nach innen wischen zum Abbrechen, nach oben zum Sperren';

  @override
  String get voiceWaveformScrubberSemantic =>
      'Positionsregler der Sprachnachricht';

  @override
  String get voiceChatTitle => 'Sprachchat';

  @override
  String get voiceMicPermissionRequired =>
      'Für Audioaufnahmen wird Mikrofonzugriff benötigt.';

  @override
  String get voiceCouldNotStartRecording =>
      'Aufnahme konnte auf diesem Gerät nicht gestartet werden.';

  @override
  String get voiceTapMicEmptyPrompt =>
      'Tippe unten aufs Mikrofon, um eine Sprachnachricht aufzunehmen';

  @override
  String get voiceTapMicInputHint => 'Mikro tippen für Sprachnotiz...';

  @override
  String get voiceToggleWaveformTooltip => 'Wellenform-Ansicht wechseln';

  @override
  String get voiceToggleThemeTooltip => 'GTA-6-Design wechseln';

  @override
  String get otpVerifyCodeTitle => 'Code bestätigen';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return 'Gib den 6-stelligen Code ein, der an $destination gesendet wurde';
  }

  @override
  String get otpCodeVerifiedLabel => 'Code bestätigt';

  @override
  String get otpIncorrectCodeError => 'Code falsch, versuch es nochmal';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'Erneut senden in ${seconds}s';
  }

  @override
  String get otpResendCodeButton => 'Neu senden';

  @override
  String get welcomeContinueAsGuestLabel => 'Als Gast weiter';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'Passwort';

  @override
  String get authFullNamePlaceholder => 'Name';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'nutzername';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'Gefällt mir, $count Likes';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'Gefällt mir nicht mehr, $count Likes';
  }

  @override
  String get likeSyncFailedSemantic =>
      'Like nicht gespeichert. Tippen zum Wiederholen';

  @override
  String get pullToRefreshRefreshing => 'Wird aktualisiert';

  @override
  String get pullToRefreshRelease => 'Loslassen zum Aktualisieren';

  @override
  String get pullToRefreshPullDown => 'Nach unten ziehen zum Aktualisieren';

  @override
  String get badgeOnlineSemantic => 'Online';

  @override
  String get badgeUnreadNotificationSemantic => 'Ungelesene Mitteilung';

  @override
  String get badgeUnreadMaxSemantic => '99+ ungelesene Mitteilungen';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '$count ungelesene $notificationWord';
  }

  @override
  String get notificationSingular => 'Mitteilung';

  @override
  String get notificationPlural => 'Mitteilungen';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return 'Mit $emoji reagieren';
  }

  @override
  String get emojiFewerTooltip => 'Weniger Emojis';

  @override
  String get emojiMoreTooltip => 'Mehr Emojis';

  @override
  String get listingFavoriteTooltip => 'Anzeige merken';

  @override
  String get accommodationFavoriteTooltip => 'Unterkunft merken';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedrooms Schlafzimmer';
  }

  @override
  String get listingTaxesIncluded => 'inkl. Steuern';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '$total gesamt · $nights Nächte';
  }

  @override
  String get boostActionLabel => 'Boosten';

  @override
  String get liveBadgeLabel => 'LIVE';

  @override
  String get meetingEncryptionKeyHint => 'Geheimer AES-GCM-256-Bit-Schlüssel';

  @override
  String get meetingDefaultTitle => 'Apolo Meeting';

  @override
  String get meetingDefaultParticipantName => 'SFU-Teilnehmer';

  @override
  String get bugReportSafetyHeader => 'Apolo.ma Sicherheit';

  @override
  String get bugReportDescMinLengthError =>
      'Beschreibung muss mindestens 5 Zeichen lang sein.';

  @override
  String get bugReportNetworkFailedError => 'Netzwerkanfrage fehlgeschlagen.';

  @override
  String get bugReportTimeoutError =>
      'Zeitüberschreitung. Prüfe deine Verbindung und versuch es nochmal.';

  @override
  String get bugReportServerUnreachableError =>
      'Die Apolo.ma-Server sind gerade nicht erreichbar.';

  @override
  String get meetingSignInRequiredError =>
      'Bitte melde dich an, um am Meeting teilzunehmen.';

  @override
  String get meetingPermissionDeniedError =>
      'Du hast keine Berechtigung für dieses Meeting.';

  @override
  String get meetingAlreadyEndedError => 'Dieses Meeting ist bereits beendet.';

  @override
  String get meetingRoomLockedError => 'Dieser Raum wurde vom Host gesperrt.';

  @override
  String get meetingMaxCapacityError =>
      'Dieses Meeting hat die maximale Teilnehmerzahl erreicht.';

  @override
  String get meetingServiceUnreachableError =>
      'Meeting-Dienst nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get accountOnboardingFormFinishSettingUpAccount =>
      'Konto fertig einrichten';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'Wähle deine Stadt und Interessen. Du kannst jederzeit kostenlos in den Einstellungen zu einem Business-Konto wechseln.';

  @override
  String get accountOnboardingFormCity => 'Stadt';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      'Wähle mindestens ein Interesse';

  @override
  String get accountOnboardingFormSaveContinue => 'Weiter';

  @override
  String get accountOnboardingFormReloadOptions => 'Neu laden';

  @override
  String get navHome => 'Start';

  @override
  String get navExplore => 'Entdecken';

  @override
  String get sellItemButton => 'Inserieren';

  @override
  String get navStores => 'Shops';

  @override
  String get navMessages => 'Chats';

  @override
  String get navProfile => 'Profil';

  @override
  String get categoriesTitle => 'Kategorien';

  @override
  String get featuredAdsTitle => 'VIP-Anzeigen';

  @override
  String get latestAdsTitle => 'Neueste Anzeigen';

  @override
  String get allCitiesFilter => 'Alle Städte';

  @override
  String get allCategoriesFilter => 'Alle Kategorien';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get createAccountButton => 'Konto erstellen';

  @override
  String get logoutButton => 'Abmelden';

  @override
  String get callSellerButton => 'Anrufen';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get chatInAppButton => 'Chat';

  @override
  String get boostAdButton => 'Boosten';

  @override
  String get deleteAccountButton => 'Konto löschen';

  @override
  String get reportAdButton => 'Anzeige melden';

  @override
  String get blockUserButton => 'Nutzer blockieren';

  @override
  String get searchHint => 'Auto, Wohnung, Handy suchen...';

  @override
  String get noAdsFoundMessage => 'Keine passenden Anzeigen gefunden';

  @override
  String get appStateDark => 'Dunkel';

  @override
  String get appStateSystem => 'System';

  @override
  String get appStateLight => 'Hell';

  @override
  String get appStateApoloMember => 'Apolo-Mitglied';

  @override
  String get appStateJustNow => 'Gerade eben';

  @override
  String get appStateKm => 'km';

  @override
  String get bugReportReportTechnicalProblem => 'Technisches Problem melden';

  @override
  String get bugReportIfFeatureProductIsnT =>
      'Wenn eine Funktion nicht richtig klappt, schick uns gern Feedback, damit wir Apolo.ma verbessern können.';

  @override
  String get bugReportReportProblem => 'Problem melden';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      'Meldungen zu Missbrauch oder Spam gehören nicht hierher.';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'Erfahre, wie du Missbrauch, Spam, Betrug oder Regelverstöße auf Apolo.ma meldest.';

  @override
  String get bugReportShakePhoneReportProblem =>
      'Handy schütteln, um Problem zu melden';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'Aktiv für Mobil-Sensoren (Desktop-Browser hat keinen Beschleunigungssensor)';

  @override
  String get bugReportToggleEnable => 'Einschalten zum Aktivieren';

  @override
  String get bugReportToggleOffDisable => 'Ausschalten zum Deaktivieren';

  @override
  String get bugReportReportTechnicalProblem2 => 'Technisches Problem melden';

  @override
  String get bugReportLearnMoreAboutReportingAbuse =>
      'Mehr zum Melden von Missbrauch oder Spam';

  @override
  String get bugReportWouldYouLikeIncludeAdditional =>
      'Möchtest du zusätzliche Protokolle und Diagnosedaten mitsenden?';

  @override
  String get bugReportAlwaysCollectedBasicContext =>
      'Immer erfasste Basisdaten:';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'Deine Nutzer-ID (falls angemeldet), App-Version/Build, Plattform/OS, aktueller Bildschirm und Sprach-/RTL-Status.';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      'Optionale Diagnosedaten (nur mit deiner Zustimmung):';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      'Letzte App-Logs, Navigations- und bereinigte API-Fehlerhinweise sowie Geräte-/Anzeigedaten zum Nachstellen des Fehlers.';

  @override
  String get bugReportIncludeContinue => 'Mitsenden';

  @override
  String get bugReportDonTIncludeContinue => 'Ohne weiter';

  @override
  String get sendButton => 'Senden';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      'Beschreibe kurz, was passiert ist oder nicht funktioniert.';

  @override
  String get bugReportScreenshot => 'Screenshot';

  @override
  String get bugReportUpload => 'Hochladen';

  @override
  String get bugReportRemoveScreenshot => 'Screenshot entfernen';

  @override
  String get bugReportPreviewScreenshot => 'Screenshot ansehen';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'Automatischer Screenshot war hier nicht möglich – nutze stattdessen Hochladen.';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      'Bitte beschreibe kurz, was passiert ist, bevor du sendest.';

  @override
  String get bugReportPleaseWriteAtLeast5 =>
      'Bitte schreibe mindestens 5 Zeichen zur Beschreibung.';

  @override
  String get bugReportImageExceeds5MbMaximum =>
      'Das Bild ist größer als das 5-MB-Limit.';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      'Bildformat nicht unterstützt. Bitte wähle JPEG, PNG oder WebP.';

  @override
  String get bugReportCouldNotReadSelectedImage =>
      'Das ausgewählte Bild konnte nicht gelesen werden.';

  @override
  String get retryButton => 'Nochmal';

  @override
  String get closeButton => 'Schließen';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return 'Danke! Deine Fehlermeldung ist eingegangen (#$reportId)';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      'Danke! Deine Fehlermeldung ist eingegangen.';

  @override
  String get bugReportCouldNotSendReportRight =>
      'Meldung konnte gerade nicht gesendet werden. Prüfe deine Verbindung und versuch es nochmal.';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return 'Zu viele Meldungen in kurzer Zeit. Bitte versuch es in $seconds Sekunden nochmal.';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      'Zu viele Meldungen in kurzer Zeit. Bitte warte kurz und versuch es nochmal.';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues =>
      'Missbrauch, Spam & Sicherheitsprobleme melden';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'Dieses Formular ist nur für technische Fehler. Um verdächtige Anzeigen, Belästigung, Betrug oder Verstöße auf Apolo.ma zu melden, tippe in der Anzeige oder im Chat auf „Melden“ oder öffne unten unser Sicherheitsformular.';

  @override
  String get bugReportOpenSafetyAbuseReport => 'Sicherheitsmeldung öffnen';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      'Fehler entdeckt? Sende uns einen kurzen Bericht, gern mit Screenshot.';

  @override
  String get meetingLobby => 'Meeting-Lobby';

  @override
  String get meetingNewGroupMeeting => 'Neues Gruppen-Meeting';

  @override
  String get meetingJoinRoomCode => 'Mit Raumcode beitreten';

  @override
  String get meetingTitle => 'Meeting-Titel';

  @override
  String get meetingEGLivePropertyWalkthrough =>
      'z. B. Live-Wohnungsbesichtigung';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'Raumcode (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'Beitreten';

  @override
  String get meetingStartMeeting => 'Starten';

  @override
  String get meetingEndEndEncryptionE2ee =>
      'Ende-zu-Ende-Verschlüsselung (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'SFU leitet verschlüsselte Pakete weiter, ohne deine Medien je einzusehen';

  @override
  String get meetingSharedRoomEncryptionKey => 'Gemeinsamer Raumschlüssel';

  @override
  String get meetingAdaptiveSfuSvc25Participants =>
      'Adaptives SFU + SVC (25+ Teilnehmer)';

  @override
  String get meetingMicOn => 'Mikro an';

  @override
  String get meetingMuted => 'Stumm';

  @override
  String get meetingCameraOn => 'Kamera an';

  @override
  String get meetingCameraOff => 'Kamera aus';

  @override
  String get meetingShareScreen => 'Teilen';

  @override
  String get meetingStopSharing => 'Stoppen';

  @override
  String get meetingSpeaker => 'Lautsprecher';

  @override
  String get meetingFlipCamera => 'Wechseln';

  @override
  String get meetingParticipants => 'Teilnehmer';

  @override
  String get meetingLeave => 'Verlassen';

  @override
  String get meetingEndAll => 'Für alle beenden';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      'Instabiles Netz... Automatische Neuverbindung über UDP/TURN';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      'Schwache Verbindung: Videoqualität reduziert (SVC), um Ton & Akku zu schonen';

  @override
  String get meetingAudioOnly => 'Nur Audio';

  @override
  String get meetingResumeVideo => 'Video an';

  @override
  String get meetingDataBatterySaverAudioOnly =>
      'Daten- & Akkusparmodus (Nur Audio) aktiv';

  @override
  String get meetingYou => 'Du';

  @override
  String get meetingHost => 'Host';

  @override
  String get meetingCoHost => 'Co-Host';

  @override
  String get meetingLockRoom => 'Sperren';

  @override
  String get meetingUnlockRoom => 'Entsperren';

  @override
  String get meetingMuteMic => 'Stummschalten';

  @override
  String get meetingRemove => 'Entfernen';

  @override
  String get meetingCopyInviteLink => 'Link kopieren';

  @override
  String get meetingInviteCopied => 'Link kopiert';

  @override
  String get meetingConnectingSecureSfuMediaRouter =>
      'Verbinde mit sicherem SFU-Medienrouter...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return 'Seite $current von $total';
  }

  @override
  String get accountSecurityEnterValidEmailAddress =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get accountSecurityEnterValidPhoneNumber =>
      'Bitte gib eine gültige Telefonnummer ein.';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      'Kontaktdaten erfolgreich aktualisiert.';

  @override
  String get accountSecurityPasswordMustBeAtLeast =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get accountSecurityPasswordsDoNotMatch =>
      'Die Passwörter stimmen nicht überein.';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully =>
      'Passwort erfolgreich aktualisiert.';

  @override
  String get accountSecurityAccountSecurity => 'Kontosicherheit';

  @override
  String get accountSecurityStayControlLogin =>
      'Behalte die Kontrolle über deinen Login';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'Ändere dein Passwort, deine E-Mail oder Telefonnummer direkt in der App.';

  @override
  String get accountSecurityContactDetails => 'Kontaktdaten';

  @override
  String get accountSecurityEmailAddress => 'E-Mail-Adresse';

  @override
  String get accountSecurityPhoneNumber => 'Telefonnummer';

  @override
  String get accountSecuritySaveContactDetails => 'Kontaktdaten speichern';

  @override
  String get accountSecurityChangePassword => 'Passwort ändern';

  @override
  String get accountSecurityCurrentPassword => 'Aktuelles Passwort';

  @override
  String get accountSecurityNewPassword => 'Neues Passwort';

  @override
  String get accountSecurityConfirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get accountSecurityUpdatePassword => 'Passwort speichern';

  @override
  String get accountSecuritySecurityOptions => 'Sicherheitsoptionen';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'Melde dich an, um diese Daten zu ändern';

  @override
  String get accountSetupCreateAccount => 'Konto erstellen';

  @override
  String get accountSetupAccountType => 'Kontotyp';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'Wähle mindestens einen Profiltyp, um dein Konto anzupassen.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get adDetailHiIsThisStillAvailable =>
      'Hallo, ist der Artikel noch da?';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'Merkliste konnte nicht aktualisiert werden. Bitte versuch es nochmal.';

  @override
  String get adDetailPhoneNumberCopied => 'Telefonnummer kopiert';

  @override
  String get adDetailCopy => 'Kopieren';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'Chat konnte nicht gestartet werden. Bitte versuch es nochmal.';

  @override
  String get adDetailUserBlocked => 'Nutzer blockiert';

  @override
  String get adDetailReportThisListingAiContent =>
      'Anzeige oder KI-Inhalt melden';

  @override
  String get adDetailQuickReviewByTrustSafety =>
      'Schnelle Prüfung durch unser Sicherheitsteam';

  @override
  String get adDetailHideAllListingsFromThis =>
      'Alle Anzeigen dieses Verkäufers ausblenden';

  @override
  String get adDetailDetails => 'Details';

  @override
  String get adDetailListingUnavailable => 'Anzeige nicht verfügbar';

  @override
  String get adDetailThisItemMayHaveBeen =>
      'Dieser Artikel wurde eventuell schon verkauft oder vom Verkäufer gelöscht.';

  @override
  String get adDetailGoBack => 'Zurück';

  @override
  String get adDetailCategory => 'Kategorie';

  @override
  String get adDetailCondition => 'Zustand';

  @override
  String get adDetailNotSpecified => 'Keine Angabe';

  @override
  String get adDetailReference => 'Referenz';

  @override
  String get backButton => 'Zurück';

  @override
  String get adDetailFavorite => 'Merken';

  @override
  String get adDetailMore => 'Mehr';

  @override
  String get adDetailFree => 'Zu verschenken';

  @override
  String get adDetailOnRequest => 'Auf Anfrage';

  @override
  String get negotiableBadge => 'VB';

  @override
  String get fixedPriceBadge => 'Festpreis';

  @override
  String get adDetailGuests => 'Gäste';

  @override
  String get adDetailBedrooms => 'Schlafzimmer';

  @override
  String get adDetailBeds => 'Betten';

  @override
  String get adDetailBaths => 'Bäder';

  @override
  String get adDetailGood => 'Gut';

  @override
  String get adDetailRef => 'Ref.';

  @override
  String get adDetailViews => 'Aufrufe';

  @override
  String get adDetailGuestFavourite => 'Gäste-Favorit';

  @override
  String get adDetailVideoTour => 'Videotour';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return 'Gerade eingestellt · vor $m Min.';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return 'Gerade eingestellt · vor $h Std.';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return 'vor $d Tagen';
  }

  @override
  String get adDetailJustListed => 'Neu eingestellt';

  @override
  String get adDetailBoostThisListing => 'Anzeige boosten ⚡';

  @override
  String get adDetailMessageSeller => 'Nachricht senden';

  @override
  String get adDetailFastReply => 'Schnelle Antwort';

  @override
  String get adDetailWriteMessage => 'Nachricht schreiben...';

  @override
  String get adDetailAlertsEnabledSimilarListings =>
      'Suchauftrag für ähnliche Anzeigen aktiv';

  @override
  String get adDetailAlertsPaused => 'Suchauftrag pausiert';

  @override
  String get adDetailAlerts => 'Suchauftrag';

  @override
  String get adDetailMessage => 'Nachricht';

  @override
  String get shareButton => 'Teilen';

  @override
  String get saveButton => 'Speichern';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      'Keine Beschreibung vorhanden. Schreib dem Verkäufer für mehr Infos.';

  @override
  String get adDetailDescription => 'Beschreibung';

  @override
  String get adDetailSeeLess => 'Weniger';

  @override
  String get adDetailSeeMore => 'Mehr anzeigen';

  @override
  String get adDetailCallSeller => 'Verkäufer anrufen';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'Apolo-Shop · $cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'Apolo-Verkäufer · $cityName';
  }

  @override
  String get adDetailBusinessStore => 'Business-Shop';

  @override
  String get adDetailSeller => 'Verkäufer';

  @override
  String get adDetailSeeReviews => 'Bewertungen';

  @override
  String get followingButton => 'Gefolgt';

  @override
  String get followButton => 'Folgen';

  @override
  String get adDetailYourRating => 'Deine Bewertung';

  @override
  String get adDetailRateThisSeller => 'Verkäufer bewerten';

  @override
  String get adDetailEditReview => 'Ändern';

  @override
  String get adDetailWriteReview => 'Bewerten';

  @override
  String get adDetailLocation => 'Standort';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'In deiner Nähe · $distKm km';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return '$distKm km entfernt';
  }

  @override
  String get adDetailLocationIsApproximate => 'Ungefährer Standort';

  @override
  String get adDetailFullMap => 'Karte öffnen';

  @override
  String get adDetailRelatedSearches => 'Ähnliche Suchen';

  @override
  String get adDetailIfYouDonTLike => 'Wenn dir das nicht gefällt, kannst du ';

  @override
  String get adDetailHideThisListing => 'diese Anzeige ausblenden';

  @override
  String get adDetailWeLlShowYouFewer =>
      ' – wir zeigen dir dann weniger ähnliche Anzeigen.';

  @override
  String get adDetailListingHiddenFromFeed =>
      'Anzeige aus deinem Feed ausgeblendet';

  @override
  String get adDetailListingRestored => 'Anzeige wieder eingeblendet';

  @override
  String get adDetailHidden => 'Ausgeblendet';

  @override
  String get adDetailHideListing => 'Ausblenden';

  @override
  String get adDetailReportSafety => 'Melden & Sicherheit';

  @override
  String get adDetailSimilarListings => 'Ähnliche Anzeigen';

  @override
  String get adDetailAllReviews => 'Alle Bewertungen';

  @override
  String get adDetailSellerRating => 'Verkäuferbewertung';

  @override
  String get adDetailEditReview2 => 'Bewertung ändern';

  @override
  String get adDetailWriteReview2 => 'Bewertung schreiben';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return 'Bewertungen ($totalCount)';
  }

  @override
  String get adDetailShowAll => 'Alle zeigen';

  @override
  String get adDetail5Stars => '5 Sterne';

  @override
  String get filtersTitle => 'Filter';

  @override
  String get adDetailHighest => 'Beste';

  @override
  String get adDetailSort => 'Sortieren';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return 'Noch keine geschriebenen Bewertungen für $sellerName';
  }

  @override
  String get adDetailHelpful => 'Hilfreich';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'Komm zu Apolo.ma — Marokkos Marktplatz: https://apolo.ma';

  @override
  String get addFriendsAddFriends => 'Freunde einladen';

  @override
  String get addFriendsInvited => 'Eingeladen';

  @override
  String get addFriendsInvite => 'Einladen';

  @override
  String get addFriendsContacts => 'Kontakte';

  @override
  String get authUnableOpenGoogleSignRight =>
      'Google-Anmeldung kann gerade nicht geöffnet werden.';

  @override
  String get authUnableStartGoogleSign =>
      'Google-Anmeldung konnte nicht gestartet werden.';

  @override
  String get authNoEmailAddressIsLinked =>
      'Mit diesem Konto ist keine E-Mail-Adresse für den Code-Empfang verknüpft.';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return 'Ein Bestätigungscode wurde an $masked gesendet.';
  }

  @override
  String get authPleaseEnterValidEmailAddress =>
      'Bitte gib eine gültige E-Mail-Adresse ein';

  @override
  String get authPasswordMustBeAtLeast =>
      'Dein Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get authPleaseEnterNameAtLeast =>
      'Bitte gib deinen Namen ein (mind. 2 Zeichen)';

  @override
  String get authUsernameMustBeAtLeast =>
      'Nutzername muss mind. 3 Buchstaben oder Zahlen haben';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      'Bitte gib eine gültige marokkanische Nummer ein (z. B. 650-123456)';

  @override
  String get authEnter6DigitVerificationCode =>
      'Gib den 6-stelligen Bestätigungscode ein.';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return 'Ein neuer Bestätigungscode wurde an $masked gesendet.';
  }

  @override
  String get authNewVerificationCodeWasSent2 =>
      'Ein neuer Bestätigungscode wurde an deine E-Mail gesendet.';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue (Versuch um $hh:$mm)';
  }

  @override
  String get signUpButton => 'Registrieren';

  @override
  String get authEnterEmail => 'E-Mail eingeben';

  @override
  String get authEnterPassword => 'Passwort eingeben';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authWhatSEmail => 'Wie lautet deine E-Mail?';

  @override
  String get authChoosePassword => 'Wähle ein Passwort';

  @override
  String get authWhatSFirstName => 'Wie heißt du mit Vornamen?';

  @override
  String get authPickUsername => 'Wähle einen Nutzernamen';

  @override
  String get authOthersCanFindYouUsername =>
      'Über deinen Nutzernamen können andere dich finden!';

  @override
  String get authWhatSPhoneNumber => 'Wie lautet deine Telefonnummer?';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'Gib eine gültige marokkanische Telefonnummer ein, um dein Konto zu schützen';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return 'Wir haben einen 6-stelligen Code an $maskedEmail gesendet';
  }

  @override
  String get authWeSent6DigitVerification2 =>
      'Wir haben einen 6-stelligen Code an deine E-Mail gesendet';

  @override
  String get authEnterVerificationCode => 'Bestätigungscode eingeben';

  @override
  String get authSending => 'Wird gesendet...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'Neu senden (${remaining}s)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      'Willkommen in unserem Shop auf Apolo! Wie können wir dir heute helfen?';

  @override
  String get businessSwitchPleaseEnterStoreNameAt =>
      'Bitte gib einen Shop-Namen ein (mind. 2 Zeichen).';

  @override
  String get businessSwitchPleaseEnterStoreName =>
      'Bitte gib deinen Shop-Namen ein.';

  @override
  String get businessSwitchBusinessProfileUpdated =>
      'Business-Profil aktualisiert!';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      'Dein verifizierter Business-Shop ist jetzt aktiv!';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'Business-Profil konnte nicht gespeichert werden. Versuch es nochmal.';

  @override
  String get businessSwitchBusinessSettings => 'Business-Einstellungen';

  @override
  String get businessSwitchSwitchBusiness => 'Zu Business wechseln';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      'Deine bisherigen Shop-Daten sind bereit zur Reaktivierung!';

  @override
  String get savingLabel => 'Speichert...';

  @override
  String get businessSwitchSaveChanges => 'Speichern';

  @override
  String get businessSwitchActivateFreeBusiness => 'Business gratis starten';

  @override
  String get businessSwitchWhatBestDescribesBusiness =>
      'Was beschreibt dein Business am besten?';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'Dieses Kategorie-Badge erscheint unter deinem Namen im Profil und Shop.';

  @override
  String get businessSwitchStoreIdentityHoursLocation =>
      'Shop-Infos, Öffnungszeiten & Standort';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      'Dein Shop erscheint im Shop-Verzeichnis, sobald du mindestens 1 aktive Anzeige hast.';

  @override
  String get businessSwitchStoreName => 'Shop-Name *';

  @override
  String get businessSwitchEGAutoCasa => 'z. B. Auto Casa';

  @override
  String get businessSwitchBioDescription => 'Kurzinfo / Beschreibung';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      'Erzähl Käufern etwas über deine Produkte & deinen Service...';

  @override
  String get businessSwitchCityAddress => 'Stadt & Adresse';

  @override
  String get businessSwitchEGMaarifCasablanca => 'z. B. Maarif, Casablanca';

  @override
  String get businessSwitchGoogleMapsLinkOptional =>
      'Google Maps-Link (optional)';

  @override
  String get businessSwitchWorkingHours => 'Öffnungszeiten';

  @override
  String get businessSwitchContactDirectOrderTools =>
      'Kontakt & Direktbestellung';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'Aktiviere 1-Klick-Bestellungen und automatische Chat-Begrüßungen.';

  @override
  String get businessSwitchBusinessPhone => 'Geschäftstelefon';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      '„Direkt bestellen“-Button im Shop aktivieren';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'Erhalte Sofortbestellungen direkt mit Kundendaten.';

  @override
  String get businessSwitchAutoGreetingMessageChat =>
      'Automatische Begrüßung im Chat';

  @override
  String get businessSwitchWelcomeStoreHowCanWe =>
      'Willkommen in unserem Shop! Wie können wir helfen?';

  @override
  String get callIncomingVideoCall => 'Eingehender Videoanruf...';

  @override
  String get callIncomingVoiceCall => 'Eingehender Sprachanruf...';

  @override
  String get callRinging => 'Klingelt...';

  @override
  String get callAllowMicCameraAccess => 'Mikro-/Kamerazugriff erlauben';

  @override
  String get callConnecting => 'Verbinde...';

  @override
  String get callCalls => 'Anrufe';

  @override
  String get callCallsAreUnavailableThisDevice =>
      'Anrufe sind auf diesem Gerät nicht verfügbar';

  @override
  String get callBackChat => 'Zurück zum Chat';

  @override
  String get callVideoCall => 'Videoanruf';

  @override
  String get callVoiceCall => 'Sprachanruf';

  @override
  String get callDecline => 'Ablehnen';

  @override
  String get callAccept => 'Annehmen';

  @override
  String get callMic => 'Mikro';

  @override
  String get callCamera => 'Kamera';

  @override
  String get callEnd => 'Beenden';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return 'Letzte Nachricht $lastTime';
  }

  @override
  String get chatListUnpinChat => 'Chat lösen';

  @override
  String get chatListPinChat => 'Chat anpinnen';

  @override
  String get chatListChatUnpinned => 'Chat gelöst';

  @override
  String get chatListChatPinnedTop => 'Chat oben angepinnt';

  @override
  String get chatListMarkAsRead => 'Als gelesen markieren';

  @override
  String get chatListUnmuteNotifications => 'Ton einschalten';

  @override
  String get chatListMuteNotifications => 'Stummschalten';

  @override
  String get chatListNotificationsUnmuted => 'Mitteilungen aktiviert';

  @override
  String get chatListChatMuted => 'Chat stummgeschaltet';

  @override
  String get chatListArchiveChat => 'Chat archivieren';

  @override
  String get chatListChatArchived => 'Chat archiviert';

  @override
  String get chatListReportChat => 'Chat melden';

  @override
  String chatListBlockPeername(Object peerName) {
    return '$peerName blockieren';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return '$peerName blockiert';
  }

  @override
  String get chatListDeleteChat => 'Chat löschen';

  @override
  String get chatListChatDeleted => 'Chat gelöscht';

  @override
  String get chatListSelectConversationStartMessaging =>
      'Wähle einen Chat aus, um zu schreiben';

  @override
  String get chatListChats => 'Chats';

  @override
  String get chatListMarkAllRead => 'Alle gelesen';

  @override
  String get searchTitle => 'Suche';

  @override
  String get chatListAll => 'Alle';

  @override
  String get chatListUnread => 'Ungelesen';

  @override
  String get chatListPinned => 'Angepinnt';

  @override
  String get chatListSignViewChats => 'Melde dich an, um deine Chats zu sehen';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      'Schreibe Käufern und Verkäufern direkt und sicher.';

  @override
  String get signInButton => 'Anmelden';

  @override
  String get chatListNoUnreadChats => 'Keine ungelesenen Chats';

  @override
  String get chatListNoPinnedChats => 'Keine angepinnten Chats';

  @override
  String get chatListNoChatsYet => 'Noch keine Chats';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      'Stöbere durch Anzeigen und schreib Verkäufern direkt.';

  @override
  String get chatListExploreListings => 'Anzeigen entdecken';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      'Deine persönlichen Nachrichten sind Ende-zu-Ende-verschlüsselt';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'Nachrichten konnten nicht geladen werden. Versuch es nochmal.';

  @override
  String get chatRoomMessageEdited => 'Nachricht bearbeitet';

  @override
  String get chatRoomDeletedEveryone => 'Für alle gelöscht';

  @override
  String get chatRoomMessagePinned => 'Nachricht angepinnt';

  @override
  String get chatRoomMessageUnpinned => 'Nachricht gelöst';

  @override
  String get chatRoomMessageStarred => 'Nachricht markiert ⭐';

  @override
  String get chatRoomStarRemoved => 'Markierung entfernt';

  @override
  String get chatRoomReportConversation => 'Chat melden';

  @override
  String get chatRoomUserUnblocked => 'Blockierung aufgehoben';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return '$peerName freigeben';
  }

  @override
  String get chatRoomReply => 'Antworten';

  @override
  String get chatRoomUnpin => 'Lösen';

  @override
  String get chatRoomPin => 'Anpinnen';

  @override
  String get chatRoomUnstar => 'Stern weg';

  @override
  String get chatRoomStar => 'Merken';

  @override
  String get chatRoomCopied => 'Kopiert';

  @override
  String get editButton => 'Ändern';

  @override
  String get reportButton => 'Melden';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get chatRoomDeleteEveryone => 'Für alle löschen';

  @override
  String get chatRoomMorocco => 'Marokko';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 Mein Standort: $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 Preisvorschlag für \"$title\": DH $cleaned';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 Preisvorschlag: DH $cleaned';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      'Kein Ton aufgenommen. Bitte erlaube den Mikrofonzugriff und versuch es nochmal.';

  @override
  String get chatRoomVoiceMessageIsTooLong =>
      'Sprachnachricht ist zu lang. Bitte nimm eine kürzere auf.';

  @override
  String get chatRoomThisMessageWasDeleted => 'Diese Nachricht wurde gelöscht';

  @override
  String get chatRoomRead => 'Gelesen';

  @override
  String get chatRoomDelivered => 'Zugestellt';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return 'Zuletzt online $clock';
  }

  @override
  String get chatRoomOffline => 'Offline';

  @override
  String get chatRoomVideoCallUnavailable => 'Videoanruf — nicht verfügbar';

  @override
  String get chatRoomVoiceCallUnavailable => 'Sprachanruf — nicht verfügbar';

  @override
  String get chatRoomSafetyReport => 'Sicherheit & Melden';

  @override
  String get chatRoomYouBlockedThisUser => 'Du hast diesen Nutzer blockiert';

  @override
  String get chatRoomUnblock => 'Freigeben';

  @override
  String get chatRoomEditingMessage => 'Nachricht bearbeiten';

  @override
  String get chatRoomSendMessage => 'Nachricht senden';

  @override
  String get editProfileMinimum3CharactersRequired =>
      'Mindestens 3 Zeichen erforderlich';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return '@$clean ist frei';
  }

  @override
  String get editProfileAlreadyTaken => 'Schon vergeben.';

  @override
  String get editProfileProfilePhoto => 'Profilbild';

  @override
  String get editProfileChooseFromLibrary => 'Aus Galerie wählen';

  @override
  String get editProfileTakePhoto => 'Foto aufnehmen';

  @override
  String get editProfileRemoveCurrentPhoto => 'Aktuelles Foto entfernen';

  @override
  String get editProfileChoosePresetAvatar => 'Oder wähle einen Avatar';

  @override
  String get editProfileSelectCity => 'Stadt wählen';

  @override
  String get clearButton => 'Leeren';

  @override
  String get editProfilePhoneWhatsapp => 'Telefon & WhatsApp';

  @override
  String get confirmButton => 'Bestätigen';

  @override
  String get editProfileNameIsRequired => 'Name ist erforderlich.';

  @override
  String get editProfileUsernameMustBeAtLeast =>
      'Nutzername muss mindestens 3 Zeichen lang sein.';

  @override
  String get editProfileThisUsernameIsAlreadyTaken =>
      'Dieser Nutzername ist schon vergeben.';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      'Änderungen konnten nicht gespeichert werden. Versuch es nochmal.';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get editProfileEditPicture => 'Bild ändern';

  @override
  String get editProfileFullName => 'Dein vollständiger Name';

  @override
  String get editProfileUsername => 'Nutzername';

  @override
  String get editProfileBio => 'Über mich';

  @override
  String get editProfileWriteShortBioAboutYourself =>
      'Schreib kurz etwas über dich...';

  @override
  String get editProfileAddCity => 'Stadt hinzufügen';

  @override
  String get editProfilePhone => 'Telefon';

  @override
  String get editProfileAddPhoneNumber => 'Telefonnummer hinzufügen';

  @override
  String get editProfileManageStoreDetails => 'Shop-Daten verwalten';

  @override
  String get editProfileGetVerifiedBusinessStore =>
      'Verifizierung & Business-Shop holen';

  @override
  String get editProfilePersonalInformation => 'Persönliche Angaben';

  @override
  String get editProfileEmailPasswordSettings =>
      'E-Mail- & Passwort-Einstellungen';

  @override
  String get saveChangesButton => 'Speichern';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return 'Wir haben einen 6-stelligen Code an $masked gesendet.';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      'Bitte gib den 6-stelligen Bestätigungscode ein.';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      'Passwort geändert und erfolgreich angemeldet!';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      'Du erhältst eine E-Mail, um ein neues Passwort festzulegen';

  @override
  String get forgotPasswordChooseNewPassword => 'Neues Passwort wählen';

  @override
  String get homeInternetConnectionLost => 'Keine Internetverbindung';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      'Prüfe deine Verbindung und versuch es nochmal, um Anzeigen zu laden.';

  @override
  String get tryAgainButton => 'Nochmal';

  @override
  String get homeWelcomeApolo => 'Willkommen bei Apolo';

  @override
  String get homeSearchCarsHomesPhonesAccounts =>
      'Autos, Wohnungen, Handys oder Profile suchen...';

  @override
  String get homeLatestListings => 'Neueste Anzeigen';

  @override
  String get homeSeeAll => 'Alle';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'Noch keine Anzeigen im Umkreis von $zoneRadiusKm km um $s';
  }

  @override
  String get homeShowAllMorocco => 'Ganz Marokko';

  @override
  String get homeChangeZone => 'Gebiet ändern';

  @override
  String get homeBrowseAllListingsMorocco =>
      'Alle Anzeigen in Marokko durchsuchen';

  @override
  String get home1MarketplaceMorocco => 'Nr. 1 Marktplatz in Marokko 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen =>
      'Sicher kaufen und verkaufen – ganz ohne Zwischenhändler';

  @override
  String get homeCarsPhonesRealEstateDiscover =>
      'Autos, Handys, Immobilien. Entdecke Angebote in deiner Nähe.';

  @override
  String get homeExclusiveDeals => 'Exklusive Deals';

  @override
  String get homeWhyChooseApolo => 'Warum Apolo?';

  @override
  String get home0CommissionFree => '0 % Provision & Kostenlos';

  @override
  String get homeBuySellFreeZeroMiddlemen =>
      'Kostenlos kaufen und verkaufen – direkt und ohne Gebühren.';

  @override
  String get homeDirectChatCall => 'Direkter Chat & Anruf';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      'Schreib Verkäufern direkt und mach mit einem Tipp ein Angebot.';

  @override
  String get homeVerifiedListings => 'Geprüfte Anzeigen';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      'Laufende Prüfung, damit jeder Handel sicher bleibt.';

  @override
  String get homeGotSomethingSellPostNow =>
      'Willst du etwas verkaufen? Jetzt inserieren';

  @override
  String get homePublishFree30SecondsGet =>
      'In 30 Sekunden kostenlos online stellen und schnell Anfragen erhalten';

  @override
  String get homePost => 'Inserieren +';

  @override
  String get homeVerifiedOfficialStores => 'Geprüfte offizielle Shops';

  @override
  String get homeBrowseDealsFromCertifiedStores =>
      'Entdecke Angebote von zertifizierten Händlern und Agenturen';

  @override
  String get intentOnboardingWhatWillYouUseApolo =>
      'Wofür möchtest du\nApolo nutzen?';

  @override
  String get mainShellYouHaveNewApoloNotification =>
      'Du hast eine neue Apolo-Mitteilung';

  @override
  String get mainShellBrowse => 'Stöbern';

  @override
  String get notificationsEnableNotifications => 'Mitteilungen aktivieren';

  @override
  String get notificationsAreBlocked => 'Mitteilungen sind blockiert';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      'Bitte aktiviere Mitteilungen in deinen Handy- oder Browser-Einstellungen und tippe dann erneut auf Weiter.';

  @override
  String get notificationsGotIt => 'Verstanden';

  @override
  String get notificationsNotificationPreferences =>
      'Mitteilungs-Einstellungen';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      'Wähle aus, welche Apolo-Infos du erhalten möchtest';

  @override
  String get notificationsMessagesBuyerOffers =>
      'Nachrichten & Preisvorschläge';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      'Sofort-Info, wenn dir jemand schreibt oder ein Angebot macht';

  @override
  String get notificationsPriceDropsSavedListings =>
      'Preissenkungen & Merkliste';

  @override
  String get notificationsUpdatesListingsYouBookmarked =>
      'Neuigkeiten zu deinen gemerkten Anzeigen';

  @override
  String get notificationsOfficialStoresUpdates =>
      'Offizielle Shops & Neuheiten';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'Neue Artikel von geprüften Verkäufern, denen du folgst';

  @override
  String get notificationsMarkAllAsRead => 'Alle gelesen';

  @override
  String get doneButton => 'Fertig';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      'Bitte erlaube Mitteilungen, um fortzufahren';

  @override
  String get notificationsActivatedInstantAlerts =>
      ' hat Sofort-Infos aktiviert für ';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — Nachrichten & Preisvorschläge';

  @override
  String get notificationsJustNow => 'gerade eben';

  @override
  String get notificationsApoloTeam => 'Apolo-Team';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      ' teilt einen Tipp: Füge klare Fotos hinzu, um schneller zu verkaufen.';

  @override
  String get notifications2hAgo => 'vor 2 Std.';

  @override
  String get notificationsApoloOfficialStores => 'Offizielle Apolo-Shops';

  @override
  String get notificationsUpdated => ' aktualisierte ';

  @override
  String get notificationsVerifiedCarsRealEstateTech =>
      'Geprüfte Auto-, Immobilien- & Technik-Anzeigen';

  @override
  String get notificationsAcrossAllMoroccanCities =>
      ' in allen marokkanischen Städten.';

  @override
  String get notificationsThisWeek => 'Diese Woche';

  @override
  String get notificationsNotifications => 'Mitteilungen';

  @override
  String get notificationsHeyItSApolo => 'Hey, hier ist Apolo!';

  @override
  String get notificationsIAmReadyHelpYou =>
      'Ich helfe dir gern weiter. Legen wir los?';

  @override
  String get notificationsNow => 'jetzt';

  @override
  String get notificationsNotification => 'Mitteilung';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'Mitteilungen aktivieren, um Nachrichten zu erhalten';

  @override
  String get notificationsUpdates => 'Neuigkeiten';

  @override
  String get notificationsNoNotificationsThisCategory =>
      'Keine Mitteilungen in dieser Kategorie';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      'Nachrichten, Preisvorschläge und Updates zu Anzeigen erscheinen hier.';

  @override
  String get notificationsNoInternetConnection => 'Keine Internetverbindung';

  @override
  String get notificationsCheckWiFiMobileData =>
      'Prüfe WLAN oder mobile Daten, um deine Mitteilungen zu aktualisieren.';

  @override
  String get notificationsToday => 'Heute';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'GPS-Standort nicht erkannt — bitte Stadt wählen';

  @override
  String get postAdPleaseSelectCategoryCity =>
      'Bitte wähle Kategorie und Stadt aus';

  @override
  String get postAdAddAtLeastOnePhoto =>
      'Füge mindestens ein Foto zu deiner Anzeige hinzu';

  @override
  String get postAdEnterClearTitleAtLeast =>
      'Gib einen klaren Titel ein (mind. 3 Zeichen)';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      'Gib einen gültigen Preis oder „Zu verschenken“ an und bestätige deine Nummer';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return 'Tageslimit erreicht ($maxDailyFreeAds Gratis-Anzeigen/Tag)';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return 'Privatkonten enthalten bis zu $maxDailyFreeAds kostenlose Anzeigen pro Tag. Hol dir Apolo Premium ($monthlyPremiumPriceMad MAD/Monat via Google Pay) für unbegrenzte Anzeigen, Business-Shop und Verifizierungs-Badge.';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return 'Abonnieren ($monthlyPremiumPriceMad MAD/Mon.) • Google Pay';
  }

  @override
  String get postAdMaybeLater => 'Später';

  @override
  String get postAdPleaseSignPublishListing =>
      'Bitte melde dich an, um deine Anzeige zu veröffentlichen';

  @override
  String get postAdAvailableGreatConditionApolo =>
      'In super Zustand verfügbar auf Apolo';

  @override
  String get postAdFailedPublishListing =>
      'Anzeige konnte nicht veröffentlicht werden';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'Kategorien und Städte nicht verfügbar. Nochmal';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium =>
      'Unbegrenzte Tagesanzeigen · Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return '$maxDailyFreeAds/$maxDailyFreeAds2 Tageslimit erreicht · Upgrade ($monthlyPremiumPriceMad MAD)';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return 'Heute: $todayPostedAdsCount/$maxDailyFreeAds Gratis-Anzeigen · Unbegrenzt mit Premium';
  }

  @override
  String get postAdWhereAreYouListing => 'Wo inserierst du?';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      'Wähle Kategorie und Stadt, damit Käufer in deiner Nähe dich leicht finden';

  @override
  String get postAdAddClearPhotos => 'Klare Fotos hinzufügen';

  @override
  String get postAdListingsRealClearPhotosSell =>
      'Anzeigen mit echten, klaren Fotos verkaufen sich bis zu 3x schneller';

  @override
  String get postAdDescribeItem => 'Artikel beschreiben';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'Ein klarer Titel und eine ehrliche Beschreibung schaffen Vertrauen';

  @override
  String get postAdSetPriceContact => 'Preis & Kontakt festlegen';

  @override
  String get postAdSetFairPriceReviewListing =>
      'Leg einen fairen Preis fest und prüfe deine Anzeige vor dem Veröffentlichen';

  @override
  String get postAdGpsLocationSet => 'GPS-Standort gesetzt';

  @override
  String get postAdDetectAdLocationGps => 'Standort erkennen (GPS)';

  @override
  String get postAdTapAddPhotos => 'Tippen, um Fotos hinzuzufügen';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return 'Mehr Fotos ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed =>
      'Das erste Foto wird als Titelbild genutzt';

  @override
  String get postAdGallery => 'Galerie';

  @override
  String get postAdSelectedPhotos => 'Ausgewählte Fotos';

  @override
  String get postAdCover => 'Titelbild';

  @override
  String get postAdListingTitle => 'Anzeigentitel';

  @override
  String get postAdGreat => 'Super ✓';

  @override
  String get postAdEGIphone15Pro => 'z. B. iPhone 15 Pro Max 256GB wie neu';

  @override
  String get postAdDetailedDescription => 'Genaue Beschreibung';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      'Beschreibe Zustand, Zubehör und wichtige Details...';

  @override
  String get postAdSpecifications => 'Details & Merkmale';

  @override
  String get postAdPriceMad => 'Preis (MAD)';

  @override
  String get postAdEG2500 => 'z. B. 2500';

  @override
  String get postAdHideNumber => 'Nummer verbergen';

  @override
  String get postAdListingPreview => 'Anzeigenvorschau';

  @override
  String get postAdPublishNow => 'Veröffentlichen';

  @override
  String get postAdListingUpdated => 'Anzeige aktualisiert';

  @override
  String get postAdListingIsLive => 'Deine Anzeige ist online';

  @override
  String get postAdListingIsNowVisibleBuyers =>
      'Deine Anzeige ist jetzt für Käufer auf ganz Apolo.ma sichtbar.';

  @override
  String get postAdNewListing => 'Deine neue Anzeige';

  @override
  String get postAdBackHome => 'Zum Start';

  @override
  String get postAdPostAnotherListing => 'Weitere inserieren';

  @override
  String get privacyComplianceReportAiPolicyIssue =>
      'KI- oder Regelverstoß melden';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      'Wähle einen Grund für die schnelle Prüfung durch unser Sicherheitsteam:';

  @override
  String get privacyComplianceAdditionalDetailsOptional =>
      'Weitere Details (optional)...';

  @override
  String get privacyComplianceSubmitReport => 'Melden';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      'Meldung konnte nicht gesendet werden. Versuch es nochmal.';

  @override
  String get privacyComplianceReportSubmittedSuccessfully =>
      'Meldung erfolgreich gesendet ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'Link kopiert: $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion =>
      'Kontolöschung bestätigen';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      'Möchtest du dein Konto, deine persönlichen Daten, Anzeigen und Chats wirklich dauerhaft von Apolo löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get privacyComplianceDeletePermanently => 'Endgültig löschen';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted =>
      'Dein Konto und deine Daten wurden gelöscht.';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      'Löschung konnte nicht bestätigt werden. Du bleibst angemeldet. Versuch es nochmal.';

  @override
  String get privacyCompliancePrivacyPolicies => 'Datenschutz & Regeln';

  @override
  String get privacyCompliancePrivacy => 'Datenschutz';

  @override
  String get privacyCompliancePolicies => 'Regeln';

  @override
  String get privacyComplianceDataDelete => 'Daten & Löschen';

  @override
  String get privacyComplianceUpdated2026Law0908 =>
      'Stand 2026 · Gesetz 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl =>
      'Deine Daten, deine volle Kontrolle';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      'Wir verkaufen niemals deine persönlichen Daten. Deine Angaben dienen ausschließlich deinen Anzeigen, sicheren Chats und mobilen Mitteilungen auf Apolo (ma.apolo.apoloMobile).';

  @override
  String get privacyComplianceDataWeCollect => 'Welche Daten wir nutzen';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• Kontodaten: Name, E-Mail, Telefonnummer oder sicherer Login über Google / Apple.\n• Anzeigen & Shops: Fotos, Titel, Beschreibungen, MAD-Preise und gewählte Stadt.\n• Echtzeit-Chat: Nachrichten, Medien und Emoji-Reaktionen zwischen Käufern und Verkäufern.\n• Push-Tokens (FCM / APNs): Nur für System-Mitteilungen genutzt und beim Abmelden automatisch deaktiviert.';

  @override
  String get privacyComplianceDevicePermissionsControls =>
      'Geräteberechtigungen & Kontrolle';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• Mitteilungen: Optionale Hinweise bei neuen Nachrichten auf iOS & Android; jederzeit anpassbar.\n• Kamera & Fotos: Nur abgefragt, wenn du Anzeigenfotos oder Chat-Anhänge hochlädst.\n• Ungefähres Gebiet: Umkreisfilter auf Stadtebene ohne GPS-Tracking im Hintergrund.';

  @override
  String get privacyComplianceAiSafetyAppReporting =>
      'KI-Sicherheit & Meldefunktion';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'Smarte Inserats- und Suchfunktionen bieten eine direkte Meldefunktion in der App, damit du unpassende KI-Vorschläge oder missbräuchliche Anzeigen sofort melden kannst.';

  @override
  String get privacyComplianceLegalRightsContact => 'Deine Rechte & Kontakt';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'Gemäß dem marokkanischen Gesetz 09-08 sowie den Richtlinien von App Store und Google Play hast du jederzeit das Recht auf Auskunft, Änderung oder dauerhafte Löschung deiner Daten.\n• Offizielle E-Mail: support@apolo.ma / contact@apolo.ma\n• Website: https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp =>
      'KI- oder Regelverstoß melden';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy =>
      'Datenschutzerklärung im Web';

  @override
  String get privacyComplianceTermsUseMarketplaceRules =>
      'Nutzungsbedingungen & Marktplatzregeln';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      'Klare Regeln für sicheres Kaufen & Verkaufen';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'Mit der Nutzung von Apolo stimmst du echten Anzeigen, respektvollem Umgang im Chat und fairen Marktplatzregeln zu.';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'Echte Konten & Verifizierungs-Badges';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• Konto- und Shop-Angaben müssen echt und wahrheitsgemäß sein.\n• Verifizierungs-Siegel und Verkäuferränge (Bronze bis Champion) werden nur von Apolo vergeben; Nachahmung ist verboten.';

  @override
  String get privacyComplianceListingRulesProhibitedItems =>
      'Anzeigenregeln & verbotene Artikel';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• Anzeigen müssen echte Artikel oder Dienstleistungen mit eigenen Fotos und ehrlichen Preisen zeigen.\n• Streng verboten: Fälschungen, Waffen, illegale Substanzen, verschreibungspflichtige Medikamente, Hehlerware und Vorkasse-Betrug.';

  @override
  String get privacyComplianceSafeTransactionsChatConduct =>
      'Sicher handeln & Chat-Verhalten';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• Prüfe Artikel immer persönlich an einem sicheren öffentlichen Ort und zahle niemals vorab Anzahlungen.\n• Spam, Belästigung und beleidigende Nachrichten führen zur sofortigen Sperrung; blockiere oder melde Nutzer jederzeit.';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'Pro+ Abos & Anzeigen-Boosts';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• Pro+ Abos und Boost-Upgrades werden transparent über dein App Store- oder Google Play-Konto abgerechnet.\n• Du kannst die automatische Verlängerung jederzeit mindestens 24 Stunden vor Ablauf in deinen Store-Einstellungen kündigen.';

  @override
  String get privacyComplianceOpenWebTermsPolicies => 'AGB & Regeln im Web';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      'Sofort-Löschung · App Store & Play';

  @override
  String get privacyCompliancePermanentAccountDataDeletion =>
      'Dauerhafte Konto- & Datenlöschung';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'Lösche dein Konto und alle zugehörigen persönlichen Daten direkt in der App oder über unser Web-Formular.';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted =>
      'Was dauerhaft gelöscht wird';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• Profildaten (Name, E-Mail, Telefonnummer und OAuth-Verknüpfungen).\n• Alle veröffentlichten Anzeigen, hochgeladenen Fotos und Shop-Daten.\n• Chatverläufe, Merkliste und aktive Push-Benachrichtigungs-Tokens.';

  @override
  String get privacyComplianceDeleteMyAccountNowApp =>
      'Konto jetzt löschen (in App)';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'Melde dich an, um dein Konto direkt in der App zu löschen, oder nutze den Web-Link unten.';

  @override
  String get privacyComplianceExternalWebDataDeletionLink =>
      'Externer Link zur Datenlöschung';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      'Wiederkehrende Abrechnung. Jederzeit kündbar. Die Zahlung wird bei Kaufbestätigung über dein Google Pay- / Store-Konto abgerechnet und verlängert sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf des aktuellen Zeitraums deaktiviert wird.\nAlle personenbezogenen Daten werden verarbeitet gemäß ';

  @override
  String get proPlusTermsConditions => 'Nutzungsbedingungen';

  @override
  String get proPlusAnd => ' und ';

  @override
  String get proPlusPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get proPlusSubscription => 'Abo';

  @override
  String get proPlusCancelPremiumSubscription => 'Premium-Abo kündigen?';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'Die automatische Verlängerung wird beendet, dein Shop und deine Anzeigen bleiben erhalten.';

  @override
  String get proPlusCancelMySubscription => 'Abo kündigen';

  @override
  String get proPlusKeepPremium => 'Premium behalten';

  @override
  String get proPlusYouUsePremium => 'Du nutzt Premium';

  @override
  String get proPlusGetPremium => 'Premium holen';

  @override
  String get proPlusYouHaveUnlimitedAccessAll =>
      'Du hast unbegrenzten Zugriff auf alle Premium-Vorteile';

  @override
  String get proPlusGetUnlimitedAccessAllPremium =>
      'Sichere dir unbegrenzten Zugriff auf alle Premium-Vorteile';

  @override
  String get proPlusCheckedAccountActivePurchases =>
      'Dein Konto wurde auf aktive Käufe geprüft.';

  @override
  String get proPlusHowTrialWorks => 'So läuft deine Testphase ab';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return '3 Tage kostenlos testen, danach nur $monthlyPremiumPriceMad MAD/Monat via Google Pay';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      'Starte sofort und erlebe, wie Pro Plus deine Verkäufe ankurbelt.';

  @override
  String get proPlusDay2 => 'Tag 2';

  @override
  String get proPlusWeLlRemindYouNotification =>
      'Wir erinnern dich rechtzeitig per Mitteilung, bevor deine Testphase endet.';

  @override
  String get proPlusDay3 => 'Tag 3';

  @override
  String get proPlusYouLlBeChargedDay =>
      'Abrechnung erst an Tag 3 – vorher jederzeit kündbar.';

  @override
  String get proPlusViewAllPlans => 'Alle Tarife';

  @override
  String get proPlusRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get proPlusStartFree3DayTrial => '3 Tage gratis testen';

  @override
  String get proPlusPaymentVerificationFailed =>
      'Zahlungsprüfung fehlgeschlagen.';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      'Pro Plus aktiviert! Dein Shop ist jetzt verifiziert';

  @override
  String get proPlusCouldNotLaunchGooglePay =>
      'Google Pay konnte auf diesem Gerät nicht geöffnet werden.';

  @override
  String get proPlusPayGooglePay => 'Mit Google Pay zahlen';

  @override
  String get proPlusSave25 => '25 % sparen';

  @override
  String get proPlusLifetime => 'Lifetime';

  @override
  String get proPlusBasic => 'Basic';

  @override
  String get proPlus12Months => '12 Monate';

  @override
  String get proPlusOneTime => 'Einmalig';

  @override
  String get proPlus1Month => '1 Monat';

  @override
  String get proPlusMad => 'MAD';

  @override
  String get proPlusPaywall => 'Premium';

  @override
  String get proPlusUnlockFullAccess => 'Vollen Zugang freischalten';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'Unbegrenzter Zugriff auf alle Funktionen und Vorlagen';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      'Offizieller Business-Shop + blaues Verifizierungs-Badge';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      'Unbegrenzte Anzeigen pro Tag (statt 5/Tag) + 12 Fotos';

  @override
  String get proPlus5FreeMonthlyVipBoosts =>
      '5 gratis VIP-Boosts/Monat + Pro-Statistiken & Schnellantworten';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return 'Für $priceDisplay MAD abonnieren • Google Pay';
  }

  @override
  String get proPlusNoThankYou => 'Nein danke';

  @override
  String get profileCouldNotLoadListingsPull =>
      'Anzeigen konnten nicht geladen werden. Ziehe zum Aktualisieren.';

  @override
  String get profileMyAccount => 'Mein Konto';

  @override
  String get profileSettingsSupport => 'Einstellungen & Hilfe';

  @override
  String get profileSignManageListingsSavedItems =>
      'Melde dich an, um Anzeigen, Merkliste und Chats zu verwalten.';

  @override
  String get profileSignViewProfile => 'Melde dich an, um dein Profil zu sehen';

  @override
  String get welcomeCreateAccountButton => 'Konto erstellen';

  @override
  String get profileLightMode => 'Heller Modus';

  @override
  String get profileDarkMode => 'Dunkler Modus';

  @override
  String get profileListings => 'Anzeigen';

  @override
  String get profileLikes => 'Likes';

  @override
  String get profileSaved => 'Gemerkt';

  @override
  String get shareProfileButton => 'Profil teilen';

  @override
  String get profileMyListings => 'Meine Anzeigen';

  @override
  String get profileProInsightsBoost => 'Pro-Statistik & Boost';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'Upgrade auf Apolo Premium · $monthlyPremiumPriceMad MAD/Mon.';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'Business-Shop + Verifizierungs-Badge + unbegrenzte Anzeigen via Google Pay.';

  @override
  String get profileViewStore => 'Shop ansehen';

  @override
  String get profileEditStore => 'Shop ändern';

  @override
  String get profileQuickReplies => 'Schnellantworten';

  @override
  String get profileNoListingsYet => 'Noch keine Anzeigen';

  @override
  String get profilePublishFirstListingShowcaseIt =>
      'Erstelle deine erste Anzeige – sie erscheint dann hier.';

  @override
  String get profilePostListing => 'Inserieren';

  @override
  String get profileTotalViews => 'Aufrufe gesamt';

  @override
  String get profileActiveListings => 'Aktive Anzeigen';

  @override
  String get profileAvgListing => 'Ø / Anzeige';

  @override
  String get profileBoostedListings => 'Geboostete Anzeigen';

  @override
  String get profileCallTaps => 'Anruf-Klicks';

  @override
  String get profileCustomerChats => 'Kunden-Chats';

  @override
  String get profileDirectOrders => 'Direktkäufe';

  @override
  String get profileFreeVipCredits => 'Gratis VIP-Guthaben';

  @override
  String get profileUnlockCallOrderStatsPro =>
      'Anruf- & Bestellstatistik + PRO+ Badge freischalten';

  @override
  String get profileGet3FreeVipBoosts =>
      'Sichere dir 3 gratis VIP-Boosts/Monat und Top-Sichtbarkeit.';

  @override
  String get profileViewsBreakdown => 'Aufruf-Übersicht';

  @override
  String get profileLive => 'Online';

  @override
  String get profilePublishFirstListingTrackViews =>
      'Veröffentliche deine erste Anzeige, um Aufrufe und Erfolg hier zu verfolgen.';

  @override
  String get profileTopPerformingListings => 'Top-Anzeigen';

  @override
  String get profileViews => 'Aufrufe';

  @override
  String get profileSalesTip => 'Verkaufstipp';

  @override
  String get profileAddClearPhotosFairPrice =>
      'Mit klaren Fotos und einem fairen Preis gewinnst du bei deiner ersten Anzeige schnell Käufer.';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      'Neue Fotos oder ein Boost für deine Top-Anzeige helfen dir, noch schneller zu verkaufen.';

  @override
  String get profileEditListing => 'Anzeige ändern';

  @override
  String get profileBoostThisListing => 'Anzeige boosten';

  @override
  String get profileDeleteListing => 'Anzeige löschen';

  @override
  String get profileCouldNotDeleteListingPlease =>
      'Anzeige konnte nicht gelöscht werden. Versuch es nochmal.';

  @override
  String get profileDeleteThisListing => 'Diese Anzeige löschen?';

  @override
  String get profileThisListingWillBePermanently =>
      'Die Anzeige wird dauerhaft aus deinem Profil und den Suchergebnissen entfernt.';

  @override
  String get profileListingDeletedSuccessfully =>
      'Anzeige erfolgreich gelöscht';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'Das ist dein eigenes Profil';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'Apolo-Mitglied #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => 'Gescannter Code';

  @override
  String get scanProfileCodeCodeDetected => 'Code erkannt';

  @override
  String get scanProfileCodeOpenLink => 'Link öffnen';

  @override
  String get scanProfileCodeScanAgain => 'Neu scannen';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'Taschenlampe ist in diesem Browser nicht verfügbar';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'Taschenlampe ist bei dieser Kamera nicht verfügbar';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight =>
      'Taschenlampe konnte gerade nicht umgeschaltet werden';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      'Kein QR-Code im gewählten Bild gefunden';

  @override
  String get scanProfileCodeEnterCode => 'Code eingeben';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary =>
      'Fotomediathek konnte nicht geöffnet werden';

  @override
  String get scanProfileCodeScanQrCode => 'QR-Code scannen';

  @override
  String get scanProfileCodePickQrImage => 'QR-Bild wählen';

  @override
  String get scanProfileCodeTapEnableCamera =>
      'Tippen, um Kamera zu aktivieren';

  @override
  String get scanProfileCodeEnterCodeManually => 'Manuell eingeben';

  @override
  String get scanProfileCodePleaseEnterLinkHandle =>
      'Bitte gib einen Link oder Nutzernamen ein';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'Apolo-Profillink einfügen oder @handle eingeben';

  @override
  String get scanProfileCodeOpenProfile => 'Profil öffnen';

  @override
  String get searchRecommended => 'Empfohlen';

  @override
  String get searchNewest => 'Neueste';

  @override
  String get searchLowestPrice => 'Günstigste';

  @override
  String get searchHighestPrice => 'Teuerste';

  @override
  String get searchMostViewed => 'Meistgesehen';

  @override
  String get searchFilterSort => 'Filtern & Sortieren';

  @override
  String get resetButton => 'Reset';

  @override
  String get searchSortBy => 'Sortieren nach';

  @override
  String get searchAllMorocco => 'Ganz Marokko';

  @override
  String get searchPriceRangeMad => 'Preisspanne (MAD)';

  @override
  String get searchMinPrice => 'Min. Preis';

  @override
  String get searchMaxPrice => 'Max. Preis';

  @override
  String get searchNegotiableListingsOnly => 'Nur VB-Anzeigen';

  @override
  String get searchApplyFilters => 'Anwenden';

  @override
  String get searchSignSaveSearchesListings =>
      'Melde dich an, um Suchen & Anzeigen zu speichern';

  @override
  String get searchSaved => 'Suche gespeichert';

  @override
  String get searchUnableSaveSearchRightNow =>
      'Suche kann gerade nicht gespeichert werden';

  @override
  String get searchSaveSearch => 'Suche speichern';

  @override
  String get searchNoSavedListingsYet => 'Noch keine gemerkten Anzeigen';

  @override
  String get searchTapHeartAnyListingSave =>
      'Tippe bei einer Anzeige aufs Herz, um sie hier zu merken';

  @override
  String get searchFilter => 'Filter';

  @override
  String get searchAllCategories => 'Alle Kategorien';

  @override
  String get searchAllAreas => 'Alle Orte';

  @override
  String get searchSetArea => 'Ort wählen';

  @override
  String get searchFeedView => 'Feed-Ansicht';

  @override
  String get searchGridView => 'Rasteransicht';

  @override
  String get personalAccountBadge => 'Privat';

  @override
  String get businessAccountBadge => 'Business';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'Keine Anzeigen im Umkreis von $zoneRadiusKm km um $s.';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      'Probier eine andere Kategorie oder erweitere deine Filter.';

  @override
  String get searchResetFilters => 'Filter zurücksetzen';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable =>
      'Telefonnummer des Verkäufers nicht verfügbar';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      'Wähle eine Anzeige aus, um diesem Verkäufer zu schreiben.';

  @override
  String get sellerProfileReportSeller => 'Verkäufer melden';

  @override
  String get sellerProfileBlockSeller => 'Verkäufer blockieren';

  @override
  String get sellerProfileSellerBlockedSuccessfully =>
      'Verkäufer erfolgreich blockiert';

  @override
  String get sellerProfileFollowers => 'Follower';

  @override
  String get sellerProfileRating => 'Bewertung';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return 'Privatverkäufer in $city · Direkte Antwort im Chat.';
  }

  @override
  String get sellerProfileVisitStore => 'Zum Shop';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return 'Anzeigen ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return 'Bewertungen ($count)';
  }

  @override
  String get sellerProfileTrustInfo => 'Vertrauen & Infos';

  @override
  String get sellerProfileNoListingsAvailableRightNow =>
      'Aktuell keine Anzeigen verfügbar';

  @override
  String get sellerProfile3DaysAgo => 'vor 3 Tagen';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'Sehr zuverlässiger Verkäufer, Artikel genau wie auf den Fotos und durchweg super Kontakt.';

  @override
  String get sellerProfile1WeekAgo => 'vor 1 Woche';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      'Reibungsloser Kauf, vor dem Bezahlen getestet. Absolut empfehlenswert!';

  @override
  String get sellerProfile2WeeksAgo => 'vor 2 Wochen';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      'Ehrlicher und freundlicher Verkäufer. Konnte den Laptop in Ruhe testen.';

  @override
  String get sellerProfile1MonthAgo => 'vor 1 Monat';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      'Top Abwicklung und absolut vertrauenswürdig. Schnelle Antworten im Apolo-Chat.';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '$count geprüfte Bewertungen';
  }

  @override
  String get sellerProfileGovernmentIdVerified => 'Ausweis geprüft';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'Offizielles Ausweisdokument vom Apolo-Sicherheitsteam geprüft und bestätigt.';

  @override
  String get sellerProfileVerifiedPhoneNumber => 'Bestätigte Telefonnummer';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'Telefonnummer per SMS-OTP-Code bestätigt.';

  @override
  String get sellerProfileApoloSafetyProtection => 'Apolo-Käuferschutz-Tipps';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'Wir empfehlen, den Artikel vor der Zahlung persönlich zu prüfen.';

  @override
  String get sellerProfileAvailableDeliveryMethods => 'Übergabe & Versand';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return 'Persönliche Abholung in $city oder versicherter Expressversand nach Absprache.';
  }

  @override
  String get accountCenterSwitchPersonalAccount => 'Zu Privatkonto wechseln';

  @override
  String get accountCenterReturnPersonalAccount => 'Zum Privatkonto wechseln?';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'Deine Business-Shop-Seite wird pausiert. Du kannst sie jederzeit wieder aktivieren.';

  @override
  String get accountCenterConfirmSwitch => 'Wechseln';

  @override
  String get accountCenterSwitchedPersonalAccount =>
      'Zu Privatkonto gewechselt.';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'Kontotyp konnte nicht geändert werden. Versuch es nochmal.';

  @override
  String get accountCenterApoloAccount => 'Apolo-Konto';

  @override
  String get accountCenterPersonalDetails => 'Persönliche Daten';

  @override
  String get accountCenterEmailPhone => 'E-Mail & Telefon';

  @override
  String get accountCenterAccountTypePreferences => 'Kontotyp & Einstellungen';

  @override
  String get accountCenterPasswordSecurity => 'Passwort & Sicherheit';

  @override
  String get accountCenterResetPassword => 'Passwort zurücksetzen';

  @override
  String get accountCenterBusinessStore => 'Business & Shop';

  @override
  String get accountCenterEditStoreProfile => 'Shop-Profil bearbeiten';

  @override
  String get accountCenterSwitchBusinessAccount => 'Zu Business-Konto wechseln';

  @override
  String get accountCenterAccountOwnership => 'Kontoverwaltung';

  @override
  String get accountCenterDeleteAccountData => 'Konto & Daten löschen';

  @override
  String get accountCenterManageApoloAccount => 'Dein Apolo-Konto verwalten';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'Melde dich an, um Sicherheit, persönliche Daten und deinen Shop zu verwalten.';

  @override
  String get logInButton => 'Anmelden';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully =>
      'App-Daten erfolgreich aktualisiert.';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'Daten konnten nicht aktualisiert werden. Prüfe deine Verbindung und versuch es nochmal.';

  @override
  String get settingsAppDataAppDataSync => 'App-Daten & Sync';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'Systeminfos und lokaler Synchronisierungsstatus mit Apolo.ma.';

  @override
  String get settingsAppDataApplicationStatus => 'App-Status';

  @override
  String get settingsAppDataAppVersion => 'App-Version';

  @override
  String get settingsAppDataServer => 'Server';

  @override
  String get settingsAppDataSyncedCategories => 'Synchronisierte Kategorien';

  @override
  String get settingsAppDataSyncedCities => 'Synchronisierte Städte';

  @override
  String get settingsAppDataActiveZone => 'Aktives Gebiet';

  @override
  String get settingsAppDataOpenSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get settingsAppDataRefreshDataNow => 'Daten aktualisieren';

  @override
  String get settingsAppearanceAppearance => 'Darstellung';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'Wähle aus, wie Apolo aussieht: Heller Modus, Dunkler Modus oder automatisch passend zu deinem Gerät.';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      'Klare helle Oberflächen und optimaler Kontrast bei Tageslicht';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      'Angenehm für die Augen bei wenig Licht und spart Akku';

  @override
  String get settingsAppearanceSystemDefault => 'Systemstandard';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'Passt sich automatisch deinem Handy- oder Browser-Design an';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return '$name freigegeben';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'Blockierte Konten';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet =>
      'Noch keine blockierten Konten';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'Nutzer oder Shops, die du in Chats oder Anzeigen blockierst, erscheinen hier und können jederzeit wieder freigegeben werden.';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser =>
      'Du kannst jeden Nutzer oder Shop jederzeit wieder freigeben.';

  @override
  String get settingsBlockedAccountsBlockedStore => 'Blockierter Shop';

  @override
  String get settingsBlockedAccountsBlockedUser => 'Blockierter Nutzer';

  @override
  String get settingsBugReportQuickTrigger => 'Schnellstart';

  @override
  String get settingsBugReportDiagnosticsSummary => 'Diagnose-Übersicht';

  @override
  String get settingsBugReportPlatform => 'Plattform';

  @override
  String get settingsBugReportActiveLanguage => 'Aktive Sprache';

  @override
  String get settingsBugReportHelpSupport => 'Hilfe & Support';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      'Sprache konnte nicht gespeichert werden. Versuch es nochmal.';

  @override
  String get settingsLanguageAppLanguage => 'App-Sprache';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'Wähle die Sprache für die App und Anzeigen. Änderungen gelten sofort in der gesamten App.';

  @override
  String get settingsRateAppNeedsWork => 'Ausbaufähig';

  @override
  String get settingsRateAppFair => 'Okay';

  @override
  String get settingsRateAppGreat => 'Super';

  @override
  String get settingsRateAppAwesome => 'Genial!';

  @override
  String get settingsRateAppSelectStars => 'Sterne wählen';

  @override
  String get settingsRateAppPleaseSelect15Stars =>
      'Bitte wähle 1 bis 5 Sterne.';

  @override
  String get settingsRateAppRateApp => 'App bewerten';

  @override
  String get settingsRateAppHowIsExperienceApoloMa =>
      'Wie gefällt dir Apolo.ma bisher?';

  @override
  String get settingsRateAppAddQuickNoteOptional =>
      'Kurze Notiz hinzufügen (optional)...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return 'Danke für deine Bewertung mit $rating/5!';
  }

  @override
  String get settingsRateAppSubmitRating => 'Absenden';

  @override
  String get settingsRateAppVisitApoloMa => 'Apolo.ma besuchen';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'Gemerkte Anzeige konnte nicht entfernt werden. Versuch es nochmal.';

  @override
  String get settingsSavedAdsSignViewSavedListings =>
      'Melde dich an, um deine Merkliste zu sehen';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      'Merke dir spannende Anzeigen, um sie jederzeit wiederzufinden.';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings =>
      'Merkliste konnte nicht geladen werden';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'Prüfe deine Internetverbindung und versuch es nochmal.';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      'Tippe bei einer Anzeige aufs Herz, um sie hier zu speichern.';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'Schau dir Apolo.ma an — Marokkos Marktplatz für Kleinanzeigen & Shops: $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'App teilen';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      'Marokkos Marktplatz für Kleinanzeigen und offizielle Shops. Teile die App mit Freunden und Familie.';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'App-Link kopiert: $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => 'Jetzt teilen';

  @override
  String get settingsShareAppCopyLink => 'Link kopieren';

  @override
  String get settingsShareAppShareMyQrProfile => 'Mein QR-Profil teilen';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'Bitte gib einen Vorschlag mit mindestens 5 Zeichen ein.';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      'Senden über das Netzwerk gerade nicht möglich. Versuch es nochmal oder schreib uns per E-Mail.';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'support@apolo.ma kopiert';

  @override
  String get settingsSuggestionFeature => 'Funktion';

  @override
  String get settingsSuggestionDesign => 'Design';

  @override
  String get settingsSuggestionPerformance => 'Tempo';

  @override
  String get settingsSuggestionOther => 'Sonstiges';

  @override
  String get settingsSuggestionMakeSuggestion => 'Vorschlag senden';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'Teile deine Ideen mit uns, damit wir Apolo.ma noch besser machen.';

  @override
  String get settingsSuggestionTopic => 'Thema';

  @override
  String get settingsSuggestionYourSuggestion => 'Dein Vorschlag';

  @override
  String get settingsSuggestionWriteIdeaHere =>
      'Schreib deine Idee hier auf...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      'Danke! Dein Vorschlag ist bei uns angekommen.';

  @override
  String get settingsSuggestionSubmitSuggestion => 'Senden';

  @override
  String get settingsSuggestionEmailSupportApoloMa =>
      'E-Mail an support@apolo.ma';

  @override
  String get settingsZoneMarketplaceZone => 'Suchgebiet';

  @override
  String get logOutButton => 'Abmelden';

  @override
  String get settingsLogOutAccount => 'Vom Konto abmelden?';

  @override
  String get settingsYouCanSignBackAnytime =>
      'Du kannst dich jederzeit wieder anmelden, um auf deine Anzeigen und Chats zuzugreifen.';

  @override
  String get settingsProActive => 'PRO+ Aktiv';

  @override
  String get settingsNotSubscribed => 'Kein Abo';

  @override
  String get settingsVipBoostCredits => 'VIP-Boost-Guthaben';

  @override
  String get settingsPrivacyTerms => 'Datenschutz & AGB';

  @override
  String get settingsAppDataLicenses => 'App-Daten & Lizenzen';

  @override
  String get settingsActivity => 'Einstellungen & Aktivität';

  @override
  String get settingsNoMatchingSettings => 'Keine passenden Einstellungen';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      'Probier einen anderen Suchbegriff wie Gemerkt, Sprache oder Pro+.';

  @override
  String get settingsYourAccount => 'Dein Konto';

  @override
  String get settingsHowYouUseApolo => 'Deine Apolo-Nutzung';

  @override
  String get settingsSubscriptions => 'Abos';

  @override
  String get settingsCommunityPrivacy => 'Community & Datenschutz';

  @override
  String get settingsSupport => 'Hilfe';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'Passwort, Sicherheit, persönliche Daten, Shop & Business';

  @override
  String get shareProfileProfileLinkCopied => 'Profillink kopiert';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'Schau dir $name ($handle) auf Apolo.ma an:\n$url';
  }

  @override
  String get shareProfileShareLink => 'Link teilen';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'Dein QR-Code ist privat. Wenn du ihn teilst, können andere ihn mit ihrer Kamera scannen und dein Profil direkt öffnen.';

  @override
  String get shareProfileScanCode => 'Code scannen';

  @override
  String get storeDetailReportStore => 'Shop melden';

  @override
  String get storeDetailStoreBlocked => 'Shop blockiert';

  @override
  String get storeDetailBlockStore => 'Shop blockieren';

  @override
  String get storeDetailDirectStoreOrder => 'Direktbestellung im Shop';

  @override
  String get storeDetailSelectItem => 'Artikel wählen';

  @override
  String get storeDetailFullName => 'Vollständiger Name';

  @override
  String get storeDetailDeliveryAddress => 'Lieferadresse';

  @override
  String get storeDetailOrderNotes => 'Anmerkungen';

  @override
  String get storeDetailConfirmOrder => 'Bestellen';

  @override
  String get storeDetailOrderSubmittedSuccessfully =>
      'Bestellung erfolgreich gesendet';

  @override
  String get storeDetailStoreNotFound => 'Shop nicht gefunden';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'Prüfe den Link oder stöbere durch geprüfte Shops.';

  @override
  String get storeDetailOrderNow => 'Bestellen';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return 'Geöffnet · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return 'Geschlossen · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'In Google Maps öffnen';

  @override
  String get storeDetailOrder => 'Bestellen';

  @override
  String get storeDetailProducts => 'Artikel';

  @override
  String get verifiedBadgeLabel => 'Geprüft';

  @override
  String get storeDetailDelivery => 'Versand';

  @override
  String get storeDetailStoreCatalog => 'Shop-Katalog';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '$totalStores geprüfte offizielle Shops';
  }

  @override
  String get storesSearchOfficialStores => 'Offizielle Shops suchen...';

  @override
  String get storesMostProducts => 'Meiste Artikel';

  @override
  String get storesTopRated => 'Top bewertet';

  @override
  String get storesNoMatchingStores => 'Keine passenden Shops';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      'Probier ein anderes Stichwort oder lade die Shop-Liste neu.';

  @override
  String get storesItems => 'Artikel';

  @override
  String get storesVisit => 'Zum Shop';

  @override
  String get supportCouldNotOpenMailApp =>
      'Mail-App konnte nicht geöffnet werden. Bitte schreib manuell an support@apolo.ma.';

  @override
  String get supportHowCanWeHelpYou => 'Wie können wir dir helfen?';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      'Beschreibe kurz das Problem und die Schritte davor. Du kannst gern einen Screenshot ohne sensible Daten anhängen.';

  @override
  String get supportDirectContact => 'Direkter Kontakt';

  @override
  String get supportOpenMailApp => 'Mail-App öffnen';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'Es wird nichts automatisch gesendet. Du prüfst und schickst die E-Mail selbst in deiner Mail-App ab.';

  @override
  String get supportSafetyReminder => 'Sicherheitshinweis';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'Teile niemals dein Passwort, deinen Bestätigungscode oder deine Zahlungsdaten mit anderen.';

  @override
  String get welcomeUnableStartGoogleSignRight =>
      'Google-Anmeldung kann gerade nicht gestartet werden.';

  @override
  String get welcomeContinueGoogle => 'Weiter mit Google';

  @override
  String get welcomeOr => 'oder';

  @override
  String get welcomeIHaveAccount => 'Ich habe ein Konto';

  @override
  String get welcomeNewOfferReceivedListing =>
      'Neuer Preisvorschlag für deine Anzeige!';

  @override
  String get welcomeY => 'Y';

  @override
  String get welcomeYassineCasablanca => 'Yassine • Casablanca';

  @override
  String get welcomeYesAvailableWelcome => 'Ja, noch da! Schreib mir gern.';

  @override
  String get accommodationCardSintraPortugal => 'Sintra, Portugal';

  @override
  String get accommodationCardExclusiveDeal => 'Exklusiver Deal';

  @override
  String get adCardVip => 'VIP';

  @override
  String get safetyReportMessage => 'Nachricht melden';

  @override
  String get safetyReportListing => 'Anzeige melden';

  @override
  String get safetyReportUser => 'Nutzer melden';

  @override
  String get safetyAlsoBlockThisAccount => 'Dieses Konto auch blockieren';

  @override
  String get safetySubmitReport => 'Melden';

  @override
  String get safetyReportSubmittedSuccessfully =>
      'Meldung erfolgreich gesendet';

  @override
  String get safetyBlockedAccounts => 'Blockierte Konten';

  @override
  String get boostCouldNotCompletePayment =>
      'Zahlung konnte nicht abgeschlossen werden';

  @override
  String get boostListingBoosted => 'Anzeige geboostet!';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'Zahlung nicht bestätigt. Bitte kontaktiere den Support vor einem neuen Versuch.';

  @override
  String get boostVipBoostActivatedUsingPro =>
      'VIP-Boost mit deinem Pro+ Guthaben aktiviert!';

  @override
  String get boostListing => 'Anzeige boosten';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'Gratis-VIP mit Pro+ aktivieren ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts =>
      'Hol dir 3 gratis VIP-Boosts/Monat mit Apolo Pro+';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      'Tarife sind aktuell nicht verfügbar. Bitte versuch es später nochmal.';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'Schneller Web-Checkout ist für dein Konto aktiviert.';

  @override
  String get boostActivateBoostNow => 'Jetzt boosten';

  @override
  String get chatUtilsYesterday => 'Gestern';

  @override
  String get guestFavoriteBadge => 'Gäste-Favorit';

  @override
  String get exploreListingCardContactSeller => 'Kontaktieren';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      'Standort nicht automatisch erkannt — wähle unten deine Stadt';

  @override
  String get marketplaceZoneMarketplaceLocation => 'Suchstandort';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal =>
      'Zeige nur Anzeigen in deiner Umgebung';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress =>
      'Viertel, Stadt oder Adresse suchen...';

  @override
  String get marketplaceZoneNationwide => 'Landesweit';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically =>
      'Meinen Standort automatisch erkennen';

  @override
  String get marketplaceZoneDistanceRadius => 'Umkreis';

  @override
  String get marketplaceZoneAllMorocco => 'Ganz Marokko';

  @override
  String get marketplaceZoneSelectCity => 'Stadt wählen';

  @override
  String get marketplaceZoneApplyZone => 'Übernehmen';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return 'Limit erreicht ($maxAllowed). Hol dir Pro Plus für mehr!';
  }

  @override
  String get quickRepliesQuickRepliesSaved => 'Schnellantworten gespeichert ⚡';

  @override
  String get quickRepliesChatQuickReplies => 'Chat-Schnellantworten';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'Tippe im Chat auf eine Vorlage, um Käufern mit einem Tipp zu antworten.';

  @override
  String get quickRepliesAddQuickReply => 'Vorlage hinzufügen';

  @override
  String get quickRepliesLabel => 'Kurzname';

  @override
  String get quickRepliesReplyText => 'Antworttext...';

  @override
  String get quickRepliesAutoGreetingMessage => 'Automatische Begrüßung';

  @override
  String get quickRepliesWelcomeStore => 'Willkommen in unserem Shop!';

  @override
  String get quickRepliesSaveQuickReplies => 'Speichern';

  @override
  String get quickRepliesManage => 'Verwalten';

  @override
  String get realMarketplaceMapApproximateMapArea =>
      'Ungefährer Kartenausschnitt';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return '$distKm km von dir';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'Gebiet wählen';

  @override
  String get badgesKitBronze => 'Bronze';

  @override
  String get badgesKitSilver => 'Silber';

  @override
  String get badgesKitGold => 'Gold';

  @override
  String get badgesKitPlatinum => 'Platin';

  @override
  String get badgesKitDiamond => 'Diamant';

  @override
  String get badgesKitChampion => 'Champion';

  @override
  String get badgesKitStarterMemberApolo => 'Neues Mitglied auf Apolo';

  @override
  String get badgesKitVerifiedAccount2Listings =>
      'Verifiziertes Konto oder 2+ Anzeigen';

  @override
  String get badgesKitBusinessStore5Listings =>
      'Business-Shop oder 5+ Anzeigen';

  @override
  String get badgesKitActiveProActiveStore8 =>
      'Aktives Pro+ oder aktiver Shop (8+)';

  @override
  String get badgesKitPro10Listings1500 =>
      'Pro+ mit 10+ Anzeigen oder 1.500 Aufrufen';

  @override
  String get badgesKitTopTierPro20Listings =>
      'Top-Stufe: Pro+ mit 20+ Anzeigen oder 5.000 Aufrufen';

  @override
  String get badgesKitSellerRank => 'Verkäuferrang:';

  @override
  String get badgesKitTopRankUnlockedApolo =>
      'Höchster Rang auf Apolo freigeschaltet!';

  @override
  String get badgesKitNext => 'Nächster:';

  @override
  String get badgesKitTrustSellerRanks => 'Vertrauen & Verkäuferränge';

  @override
  String get badgesKitCurrentRank => 'Aktueller Rang:';

  @override
  String get badgesKitVerifiedApoloAccount => 'Verifiziertes Apolo-Konto';

  @override
  String get badgesKitVerifiedSeal => 'Verifizierungs-Siegel';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      'Identität und Kontaktdaten geprüft für sicheres Handeln.';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      'Erhältst du durch Bestätigen deiner Telefonnummer oder Aktivieren eines Pro-Shops.';

  @override
  String get badgesKitAllSellerRanks => 'Alle Verkäuferränge';

  @override
  String get badgesKitCurrent => 'Aktuell';

  @override
  String get infeedUpgradeCardYourProfile => 'dein_profil';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'Schaffe mehr Vertrauen bei Käufern mit Apolo Premium.';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'Profil upgraden';

  @override
  String get infeedUpgradeCardNotNow => 'Später';

  @override
  String get searchSuggestionsSearchUsernames => 'Nutzernamen suchen';

  @override
  String get searchSuggestionsSuggestions => 'Vorschläge';

  @override
  String get searchSuggestionsRecentSearches => 'Letzte Suchen';

  @override
  String get searchSuggestionsPopularSearches => 'Beliebte Suchen';

  @override
  String get followedButton => 'Gefolgt';

  @override
  String get writeReviewExcellent => 'Ausgezeichnet';

  @override
  String get writeReviewVeryGood => 'Sehr gut';

  @override
  String get writeReviewPoor => 'Schwach';

  @override
  String get writeReviewGreatCommunication => 'Toller Kontakt';

  @override
  String get writeReviewAsDescribed => 'Wie beschrieben';

  @override
  String get writeReviewFastResponse => 'Schnelle Antwort';

  @override
  String get writeReviewFairPrice => 'Fairer Preis';

  @override
  String get writeReviewReviewHasBeenPosted =>
      'Deine Bewertung wurde veröffentlicht';

  @override
  String get writeReviewShareExperienceThisSeller =>
      'Teile deine Erfahrung mit diesem Verkäufer...';

  @override
  String get writeReviewUpdateReview => 'Aktualisieren';

  @override
  String get writeReviewSubmitReview => 'Absenden';

  @override
  String get interestsSurveyWhatAreInterests => 'Wofür interessierst du dich?';

  @override
  String get interestsSurveyDiscoverProducts => 'Artikel entdecken';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return 'Weiter ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => 'Überspringen';

  @override
  String get priceLabel => 'Preis';

  @override
  String get conditionLabel => 'Zustand';

  @override
  String get conditionNew => 'Neu';

  @override
  String get conditionLikeNew => 'Wie neu';

  @override
  String get conditionUsed => 'Gebraucht';

  @override
  String get fulfillmentMeetInPerson => 'Abholung';

  @override
  String get fulfillmentDelivery => 'Versand';

  @override
  String get listingStatusSold => 'Verkauft';

  @override
  String get listingStatusReserved => 'Reserviert';

  @override
  String get safetyTipsTitle => 'Sicherheitstipps';
}
