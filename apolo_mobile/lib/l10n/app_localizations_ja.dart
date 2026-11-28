// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get chatPlaceholder => '出品者にメッセージを送る...';

  @override
  String get chatTypeMessageHint => 'メッセージを入力...';

  @override
  String get chatRecordingPlaceholder => '録音中...';

  @override
  String get chatAddAttachmentTooltip => 'ファイルを添付';

  @override
  String get chatMessageInputLabel => 'メッセージ入力欄';

  @override
  String get chatSendMessageTooltip => 'メッセージを送信';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return '添付予定のファイル: $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return '添付ファイル $name を削除';
  }

  @override
  String get chatDismissMessageMenu => 'メッセージメニューを閉じる';

  @override
  String get chatJumpToLatest => '最新へ移動';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count件の新着$messageWord。最新へ移動';
  }

  @override
  String get chatMessageSingular => 'メッセージ';

  @override
  String get chatMessagePlural => 'メッセージ';

  @override
  String get chatCallAndOptionsTooltip => '通話とチャット設定';

  @override
  String get chatSendFailedRetrySemantic => '、送信に失敗しました。ダブルタップで再試行';

  @override
  String get chatSendingSemantic => '、送信中';

  @override
  String get chatEditedLabel => '編集済み';

  @override
  String get chatRetrySendingTooltip => 'メッセージを再送信';

  @override
  String get chatTypingIndicatorLabel => '入力中...';

  @override
  String get chatPhotoPreviewLabel => '📷 写真';

  @override
  String get chatVoicePreviewLabel => '🎤 ボイスメッセージ';

  @override
  String get voiceMicMutedIdleSemantic =>
      'マイクがミュートです。音声が検出されません。マイクボタンを長押ししてボイスメッセージを録音';

  @override
  String get voiceHoldToRecordSemantic =>
      '長押しでボイスメッセージを録音。左にスライドでキャンセル、上にスライドでハンズフリー録音';

  @override
  String get voiceMicMutedSuffixSemantic => '。警告：マイクがミュートのため音声が検出されません';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return '指を離して音声録音をキャンセル$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'ハンズフリー録音ロック中、$timeStr$mutedSuffix。停止をタップして録音を終了';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'ボイスメッセージを録音中、$timeStr$mutedSuffix。左にスライドでキャンセル、上にスライドでロック';
  }

  @override
  String get voiceWaveformMutedSemantic => 'フラットな音声波形、マイクミュート中';

  @override
  String get voiceWaveformPreviewSemantic => '操作可能な音声プレビュー波形';

  @override
  String get voiceWaveformLiveSemantic => 'リアルタイム音声波形';

  @override
  String get voiceMicMutedWarningSemantic => 'マイクミュート警告。音声が検出されません。';

  @override
  String get voiceMicMutedBadge => 'マイクミュート中';

  @override
  String get voiceCancelRecordingTooltip => '音声録音をキャンセル';

  @override
  String get voicePauseRecordingTooltip => '録音またはプレビューを一時停止';

  @override
  String get voicePlayPreviewTooltip => '音声プレビューを再生';

  @override
  String get voiceSendVoiceMessageTooltip => 'ボイスメッセージを送信';

  @override
  String get voiceReleaseToCancelLabel => '指を離してキャンセル';

  @override
  String get voiceSlideToCancelLabel => 'スライドしてキャンセル';

  @override
  String get voiceHoldMicPrompt => 'マイクを長押ししてボイスメッセージを録音';

  @override
  String get voiceRecordButtonSemantic => 'ボイスメッセージを録音';

  @override
  String get voiceRecordGestureHint => 'タップまたは長押しで録音。内側にスライドでキャンセル、上にスライドでロック';

  @override
  String get voiceWaveformScrubberSemantic => 'ボイスメッセージ波形のシークバー';

  @override
  String get voiceChatTitle => 'ボイスチャット';

  @override
  String get voiceMicPermissionRequired => '音声を録音するにはマイクへのアクセス許可が必要です。';

  @override
  String get voiceCouldNotStartRecording => 'この端末で録音を開始できませんでした。';

  @override
  String get voiceTapMicEmptyPrompt => '下のマイクをタップしてボイスメッセージを録音';

  @override
  String get voiceTapMicInputHint => 'マイクをタップして音声メモを録音...';

  @override
  String get voiceToggleWaveformTooltip => '波形表示を切り替え（全体表示 / スクロール）';

  @override
  String get voiceToggleThemeTooltip => 'GTA 6 テーマを切り替え';

  @override
  String get otpVerifyCodeTitle => '認証コードの確認';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return '$destination に送信された6桁のコードを入力してください';
  }

  @override
  String get otpCodeVerifiedLabel => '認証完了';

  @override
  String get otpIncorrectCodeError => 'コードが正しくありません。もう一度お試しください';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'コードを再送信（あと$seconds秒）';
  }

  @override
  String get otpResendCodeButton => 'コードを再送信';

  @override
  String get welcomeContinueAsGuestLabel => 'ゲストとして続ける';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'パスワード';

  @override
  String get authFullNamePlaceholder => 'お名前';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'username';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'いいね、$count件のいいね';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'いいねを取り消す、$count件のいいね';
  }

  @override
  String get likeSyncFailedSemantic => 'いいねを保存できませんでした。タップして再試行';

  @override
  String get pullToRefreshRefreshing => 'リストを更新中';

  @override
  String get pullToRefreshRelease => '指を離して更新';

  @override
  String get pullToRefreshPullDown => '下に引っ張って更新';

  @override
  String get badgeOnlineSemantic => 'オンライン';

  @override
  String get badgeUnreadNotificationSemantic => '未読の通知';

  @override
  String get badgeUnreadMaxSemantic => '99件以上の未読通知';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '未読の$notificationWord$count件';
  }

  @override
  String get notificationSingular => '通知';

  @override
  String get notificationPlural => '通知';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return '$emoji でリアクション';
  }

  @override
  String get emojiFewerTooltip => '絵文字を折りたたむ';

  @override
  String get emojiMoreTooltip => '他の絵文字を見る';

  @override
  String get listingFavoriteTooltip => '出品をお気に入り登録';

  @override
  String get accommodationFavoriteTooltip => '宿泊先をお気に入り登録';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedroomsベッドルーム';
  }

  @override
  String get listingTaxesIncluded => '税込';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '合計 $total・$nights泊';
  }

  @override
  String get boostActionLabel => 'ブースト';

  @override
  String get liveBadgeLabel => '公開中';

  @override
  String get meetingEncryptionKeyHint => 'AES-GCM 256ビット秘密鍵';

  @override
  String get meetingDefaultTitle => 'Apolo ミーティング';

  @override
  String get meetingDefaultParticipantName => 'SFU 参加者';

  @override
  String get bugReportSafetyHeader => 'Apolo.ma セーフティ';

  @override
  String get bugReportDescMinLengthError => '5文字以上で入力してください。';

  @override
  String get bugReportNetworkFailedError => 'ネットワーク通信に失敗しました。';

  @override
  String get bugReportTimeoutError => 'リクエストがタイムアウトしました。通信環境をご確認のうえ再試行してください。';

  @override
  String get bugReportServerUnreachableError => '現在 Apolo.ma のサーバーに接続できません。';

  @override
  String get meetingSignInRequiredError => 'ミーティングに参加するにはログインしてください。';

  @override
  String get meetingPermissionDeniedError => 'このミーティングにアクセスする権限がありません。';

  @override
  String get meetingAlreadyEndedError => 'このミーティングはすでに終了しています。';

  @override
  String get meetingRoomLockedError => '現在ホストによってルームがロックされています。';

  @override
  String get meetingMaxCapacityError => 'このミーティングは参加人数の上限に達しています。';

  @override
  String get meetingServiceUnreachableError =>
      'ミーティングサービスに接続できませんでした。通信環境をご確認ください。';

  @override
  String get accountOnboardingFormFinishSettingUpAccount => 'アカウント設定を完了しましょう';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'お住まいの都市と興味のあるジャンルを選んでください。設定からいつでも無料で Business アカウントに切り替えられます。';

  @override
  String get accountOnboardingFormCity => '都市';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      '興味のあるジャンルを1つ以上選んでください';

  @override
  String get accountOnboardingFormSaveContinue => '保存して次へ';

  @override
  String get accountOnboardingFormReloadOptions => '選択肢を再読み込み';

  @override
  String get navHome => 'ホーム';

  @override
  String get navExplore => 'さがす';

  @override
  String get sellItemButton => '出品';

  @override
  String get navStores => 'ショップ';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get navProfile => 'マイページ';

  @override
  String get categoriesTitle => 'カテゴリー';

  @override
  String get featuredAdsTitle => 'VIP 出品';

  @override
  String get latestAdsTitle => '新着の出品';

  @override
  String get allCitiesFilter => 'すべての都市';

  @override
  String get allCategoriesFilter => 'すべてのカテゴリー';

  @override
  String get loginButton => 'ログイン';

  @override
  String get createAccountButton => 'アカウント作成';

  @override
  String get logoutButton => 'ログアウト';

  @override
  String get callSellerButton => '電話する';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get chatInAppButton => 'チャット';

  @override
  String get boostAdButton => '出品をブースト';

  @override
  String get deleteAccountButton => 'アカウント削除';

  @override
  String get reportAdButton => '出品を通報';

  @override
  String get blockUserButton => 'ブロックする';

  @override
  String get searchHint => '車・お部屋・スマホなどを検索...';

  @override
  String get noAdsFoundMessage => '条件に一致する出品が見つかりませんでした';

  @override
  String get appStateDark => 'ダーク';

  @override
  String get appStateSystem => 'システム設定';

  @override
  String get appStateLight => 'ライト';

  @override
  String get appStateApoloMember => 'Apolo メンバー';

  @override
  String get appStateJustNow => 'たった今';

  @override
  String get appStateKm => 'km';

  @override
  String get bugReportReportTechnicalProblem => '技術的な不具合を報告';

  @override
  String get bugReportIfFeatureProductIsnT =>
      '機能やサービスが正常に動作しない場合は、Apolo.ma の改善のためご報告ください。';

  @override
  String get bugReportReportProblem => '不具合を報告';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      '迷惑行為やスパムに関する通報はこちらからは送信しないでください。';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'Apolo.ma での迷惑行為・スパム・詐欺・規約違反の通報方法を確認する。';

  @override
  String get bugReportShakePhoneReportProblem => 'スマホを振って不具合を報告';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'モバイルセンサー用（PCブラウザには加速度センサーがありません）';

  @override
  String get bugReportToggleEnable => 'オンにして有効化';

  @override
  String get bugReportToggleOffDisable => 'オフにして無効化';

  @override
  String get bugReportReportTechnicalProblem2 => '技術的な不具合を報告';

  @override
  String get bugReportLearnMoreAboutReportingAbuse => '迷惑行為やスパムの通報について詳しく見る';

  @override
  String get bugReportWouldYouLikeIncludeAdditional => '追加のログや診断情報を含めますか？';

  @override
  String get bugReportAlwaysCollectedBasicContext => '常に収集される基本情報：';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'ログイン中のユーザーID、アプリのバージョン・ビルド番号、OS・プラットフォーム、現在の画面名、言語・表示方向の設定。';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      '任意の診断情報（同意した場合のみ添付）：';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      '不具合の再現に役立つ直近のメモリログ、画面遷移とAPIエラー履歴（個人情報は除外）、端末・画面サイズの情報。';

  @override
  String get bugReportIncludeContinue => '含めて次へ';

  @override
  String get bugReportDonTIncludeContinue => '含めずに次へ';

  @override
  String get sendButton => '送信';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      '発生した現象やうまく動かない点を簡単にご記入ください。';

  @override
  String get bugReportScreenshot => 'スクリーンショット';

  @override
  String get bugReportUpload => 'アップロード';

  @override
  String get bugReportRemoveScreenshot => 'スクリーンショットを削除';

  @override
  String get bugReportPreviewScreenshot => 'スクリーンショットを確認';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'この画面では自動キャプチャを利用できません。「アップロード」から画像を追加してください。';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      '送信する前に、発生した内容をご記入ください。';

  @override
  String get bugReportPleaseWriteAtLeast5 => '不具合の内容を5文字以上で入力してください。';

  @override
  String get bugReportImageExceeds5MbMaximum => '画像サイズが上限（5 MB）を超えています。';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      '未対応の画像形式です。JPEG、PNG、または WebP を選択してください。';

  @override
  String get bugReportCouldNotReadSelectedImage => '選択した画像を読み込めませんでした。';

  @override
  String get retryButton => '再試行';

  @override
  String get closeButton => '閉じる';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return 'ありがとうございます！不具合レポートを受け付けました（#$reportId）';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      'ありがとうございます！不具合レポートを受け付けました。';

  @override
  String get bugReportCouldNotSendReportRight =>
      '現在レポートを送信できませんでした。通信環境をご確認のうえ再試行してください。';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return '短時間に多くのレポートが送信されました。$seconds秒後に再試行してください。';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      '短時間に多くのレポートが送信されました。しばらく待ってから再試行してください。';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues => '迷惑行為・スパム・安全上の問題の通報';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'このフォームは技術的なバグ報告専用です。Apolo.ma 上の不審な出品、嫌がらせ、詐欺、規約違反を通報する場合は、該当の出品・チャット画面にある「通報」ボタンをタップするか、下の安全通報フォームをご利用ください。';

  @override
  String get bugReportOpenSafetyAbuseReport => '安全・違反通報フォームを開く';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      'バグや表示崩れを見つけましたか？スクリーンショットを添えて不具合を報告できます。';

  @override
  String get meetingLobby => 'ミーティングロビー';

  @override
  String get meetingNewGroupMeeting => '新しいグループミーティング';

  @override
  String get meetingJoinRoomCode => 'ルームコードで参加';

  @override
  String get meetingTitle => 'ミーティング名';

  @override
  String get meetingEGLivePropertyWalkthrough => '例：物件のオンライン内見';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'ルームコード (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'ミーティングに参加';

  @override
  String get meetingStartMeeting => 'ミーティングを開始';

  @override
  String get meetingEndEndEncryptionE2ee => 'エンドツーエンド暗号化 (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'SFU はメディアの中身を一切閲覧せず、暗号化されたパケットのみを転送します';

  @override
  String get meetingSharedRoomEncryptionKey => 'ルーム共通の暗号化キー';

  @override
  String get meetingAdaptiveSfuSvc25Participants => 'アダプティブ SFU + SVC（25名以上対応）';

  @override
  String get meetingMicOn => 'マイク ON';

  @override
  String get meetingMuted => 'ミュート中';

  @override
  String get meetingCameraOn => 'カメラ ON';

  @override
  String get meetingCameraOff => 'カメラ OFF';

  @override
  String get meetingShareScreen => '画面共有';

  @override
  String get meetingStopSharing => '共有を停止';

  @override
  String get meetingSpeaker => 'スピーカー';

  @override
  String get meetingFlipCamera => 'カメラ切替';

  @override
  String get meetingParticipants => '参加者';

  @override
  String get meetingLeave => '退出';

  @override
  String get meetingEndAll => '全員に対して終了';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      '通信が不安定です... UDP/TURN 経由で自動再接続中';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      '低帯域モード：音声とバッテリーを保護するため映像品質を自動調整中 (SVC)';

  @override
  String get meetingAudioOnly => '音声のみ';

  @override
  String get meetingResumeVideo => 'ビデオを再開';

  @override
  String get meetingDataBatterySaverAudioOnly => 'データ・バッテリー節約モード（音声のみ）有効';

  @override
  String get meetingYou => 'あなた';

  @override
  String get meetingHost => 'ホスト';

  @override
  String get meetingCoHost => '共同ホスト';

  @override
  String get meetingLockRoom => 'ルームをロック';

  @override
  String get meetingUnlockRoom => 'ロックを解除';

  @override
  String get meetingMuteMic => 'マイクをミュート';

  @override
  String get meetingRemove => '退出させる';

  @override
  String get meetingCopyInviteLink => '招待リンクをコピー';

  @override
  String get meetingInviteCopied => '招待リンクをコピーしました';

  @override
  String get meetingConnectingSecureSfuMediaRouter => '安全な SFU メディアルーターに接続中...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return '$current / $total ページ';
  }

  @override
  String get accountSecurityEnterValidEmailAddress => '有効なメールアドレスを入力してください。';

  @override
  String get accountSecurityEnterValidPhoneNumber => '有効な電話番号を入力してください。';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      '連絡先情報を更新しました。';

  @override
  String get accountSecurityPasswordMustBeAtLeast => 'パスワードは8文字以上で設定してください。';

  @override
  String get accountSecurityPasswordsDoNotMatch => 'パスワードが一致しません。';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully => 'パスワードを更新しました。';

  @override
  String get accountSecurityAccountSecurity => 'アカウントのセキュリティ';

  @override
  String get accountSecurityStayControlLogin => 'ログイン情報を安全に管理';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'パスワード、メールアドレス、電話番号をアプリから直接変更できます。';

  @override
  String get accountSecurityContactDetails => '連絡先情報';

  @override
  String get accountSecurityEmailAddress => 'メールアドレス';

  @override
  String get accountSecurityPhoneNumber => '電話番号';

  @override
  String get accountSecuritySaveContactDetails => '連絡先を保存';

  @override
  String get accountSecurityChangePassword => 'パスワードを変更';

  @override
  String get accountSecurityCurrentPassword => '現在のパスワード';

  @override
  String get accountSecurityNewPassword => '新しいパスワード';

  @override
  String get accountSecurityConfirmNewPassword => '新しいパスワード（確認）';

  @override
  String get accountSecurityUpdatePassword => 'パスワードを更新';

  @override
  String get accountSecuritySecurityOptions => 'セキュリティ設定';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'この情報を変更するにはログインしてください';

  @override
  String get accountSetupCreateAccount => 'アカウントを作成';

  @override
  String get accountSetupAccountType => 'アカウントの種類';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'あなたに合った利用スタイルを1つ以上選んでください。';

  @override
  String get continueButton => '次へ';

  @override
  String get adDetailHiIsThisStillAvailable => 'こんにちは、こちらはまだ購入可能でしょうか？';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'お気に入りを更新できませんでした。もう一度お試しください。';

  @override
  String get adDetailPhoneNumberCopied => '電話番号をコピーしました';

  @override
  String get adDetailCopy => 'コピー';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'チャットを開始できませんでした。もう一度お試しください。';

  @override
  String get adDetailUserBlocked => 'ユーザーをブロックしました';

  @override
  String get adDetailReportThisListingAiContent => 'この出品またはAIコンテンツを通報';

  @override
  String get adDetailQuickReviewByTrustSafety => '安全対策チームが迅速に確認します';

  @override
  String get adDetailHideAllListingsFromThis => 'この出品者のすべての出品を非表示にする';

  @override
  String get adDetailDetails => '詳細';

  @override
  String get adDetailListingUnavailable => 'この出品は現在表示できません';

  @override
  String get adDetailThisItemMayHaveBeen => 'すでに売り切れたか、出品者によって削除された可能性があります。';

  @override
  String get adDetailGoBack => '戻る';

  @override
  String get adDetailCategory => 'カテゴリー';

  @override
  String get adDetailCondition => '商品の状態';

  @override
  String get adDetailNotSpecified => '指定なし';

  @override
  String get adDetailReference => '管理番号';

  @override
  String get backButton => '戻る';

  @override
  String get adDetailFavorite => 'お気に入り';

  @override
  String get adDetailMore => 'その他';

  @override
  String get adDetailFree => '無料';

  @override
  String get adDetailOnRequest => '要相談';

  @override
  String get negotiableBadge => '値下げ交渉OK';

  @override
  String get fixedPriceBadge => '固定価格';

  @override
  String get adDetailGuests => 'ゲスト';

  @override
  String get adDetailBedrooms => '寝室';

  @override
  String get adDetailBeds => 'ベッド';

  @override
  String get adDetailBaths => 'バスルーム';

  @override
  String get adDetailGood => '状態良好';

  @override
  String get adDetailRef => '番号';

  @override
  String get adDetailViews => '閲覧数';

  @override
  String get adDetailGuestFavourite => 'ゲストに人気';

  @override
  String get adDetailVideoTour => '動画ツアー';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return '新着・$m分前';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return '新着・$h時間前';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return '$d日前';
  }

  @override
  String get adDetailJustListed => '新着';

  @override
  String get adDetailBoostThisListing => 'この出品をブースト ⚡';

  @override
  String get adDetailMessageSeller => '出品者にメッセージ';

  @override
  String get adDetailFastReply => '返信が早い';

  @override
  String get adDetailWriteMessage => 'メッセージを入力...';

  @override
  String get adDetailAlertsEnabledSimilarListings => '似た出品の新着通知をオンにしました';

  @override
  String get adDetailAlertsPaused => '通知を一時停止しました';

  @override
  String get adDetailAlerts => '通知';

  @override
  String get adDetailMessage => 'メッセージ';

  @override
  String get shareButton => '共有';

  @override
  String get saveButton => '保存';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      '商品の説明はまだありません。気になる点は出品者にメッセージで聞いてみましょう。';

  @override
  String get adDetailDescription => '商品の説明';

  @override
  String get adDetailSeeLess => '閉じる';

  @override
  String get adDetailSeeMore => 'もっと見る';

  @override
  String get adDetailCallSeller => '出品者に電話する';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'Apolo ショップ・$cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'Apolo 出品者・$cityName';
  }

  @override
  String get adDetailBusinessStore => 'Business ショップ';

  @override
  String get adDetailSeller => '出品者';

  @override
  String get adDetailSeeReviews => '評価を見る';

  @override
  String get followingButton => 'フォロー中';

  @override
  String get followButton => 'フォロー';

  @override
  String get adDetailYourRating => 'あなたの評価';

  @override
  String get adDetailRateThisSeller => 'この出品者を評価する';

  @override
  String get adDetailEditReview => 'レビューを編集';

  @override
  String get adDetailWriteReview => 'レビューを書く';

  @override
  String get adDetailLocation => 'エリア';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'マイエリア内・$distKm km';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return '$distKm km 先';
  }

  @override
  String get adDetailLocationIsApproximate => 'おおよその位置を表示しています';

  @override
  String get adDetailFullMap => '地図を拡大';

  @override
  String get adDetailRelatedSearches => '関連する検索キーワード';

  @override
  String get adDetailIfYouDonTLike => 'この出品に興味がない場合は、';

  @override
  String get adDetailHideThisListing => 'この出品を非表示';

  @override
  String get adDetailWeLlShowYouFewer => 'にすると、似た出品の表示が減ります。';

  @override
  String get adDetailListingHiddenFromFeed => 'フィードから非表示にしました';

  @override
  String get adDetailListingRestored => '出品を再表示しました';

  @override
  String get adDetailHidden => '非表示済み';

  @override
  String get adDetailHideListing => '出品を非表示にする';

  @override
  String get adDetailReportSafety => '通報・あんしん対策';

  @override
  String get adDetailSimilarListings => '似た出品';

  @override
  String get adDetailAllReviews => 'すべてのレビュー';

  @override
  String get adDetailSellerRating => '出品者の評価';

  @override
  String get adDetailEditReview2 => 'レビューを編集する';

  @override
  String get adDetailWriteReview2 => 'レビューを投稿する';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return '出品者のレビュー ($totalCount件)';
  }

  @override
  String get adDetailShowAll => 'すべて表示';

  @override
  String get adDetail5Stars => '星5つ';

  @override
  String get filtersTitle => '絞り込み';

  @override
  String get adDetailHighest => '評価の高い順';

  @override
  String get adDetailSort => '並び替え';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return '$sellerName さんへのレビューはまだありません';
  }

  @override
  String get adDetailHelpful => '参考になった';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'モロッコのフリマ＆マーケットプレイス Apolo.ma を一緒に使おう：https://apolo.ma';

  @override
  String get addFriendsAddFriends => '友だちを追加';

  @override
  String get addFriendsInvited => '招待済み';

  @override
  String get addFriendsInvite => '招待する';

  @override
  String get addFriendsContacts => '連絡先';

  @override
  String get authUnableOpenGoogleSignRight => '現在 Google ログインを開けません。';

  @override
  String get authUnableStartGoogleSign => 'Google ログインを開始できませんでした。';

  @override
  String get authNoEmailAddressIsLinked =>
      '認証コードを受け取るメールアドレスがこのアカウントに連携されていません。';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return '$masked に認証コードを送信しました。';
  }

  @override
  String get authPleaseEnterValidEmailAddress => '有効なメールアドレスを入力してください';

  @override
  String get authPasswordMustBeAtLeast => 'パスワードは8文字以上で入力してください';

  @override
  String get authPleaseEnterNameAtLeast => 'お名前を入力してください（2文字以上）';

  @override
  String get authUsernameMustBeAtLeast => 'ユーザー名は英数字3文字以上で入力してください';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      '有効なモロッコの電話番号を入力してください（例：650-123456）';

  @override
  String get authEnter6DigitVerificationCode => '6桁の認証コードを入力してください。';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return '$masked に新しい認証コードを送信しました。';
  }

  @override
  String get authNewVerificationCodeWasSent2 => 'メールアドレスに新しい認証コードを送信しました。';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue（$hh:$mm に試行）';
  }

  @override
  String get signUpButton => '新規登録';

  @override
  String get authEnterEmail => 'メールアドレスを入力';

  @override
  String get authEnterPassword => 'パスワードを入力';

  @override
  String get authForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get authWhatSEmail => 'メールアドレスを教えてください';

  @override
  String get authChoosePassword => 'パスワードを設定してください';

  @override
  String get authWhatSFirstName => 'お名前（名）を教えてください';

  @override
  String get authPickUsername => 'ユーザー名を決めましょう';

  @override
  String get authOthersCanFindYouUsername => 'ユーザー名で他のユーザーが見つけやすくなります！';

  @override
  String get authWhatSPhoneNumber => '電話番号を教えてください';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'アカウント保護のため、有効なモロッコの電話番号を入力してください';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return '$maskedEmail に6桁の認証コードを送信しました';
  }

  @override
  String get authWeSent6DigitVerification2 => 'メールアドレスに6桁の認証コードを送信しました';

  @override
  String get authEnterVerificationCode => '認証コードを入力';

  @override
  String get authSending => '送信中...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'コードを再送信 ($remaining秒)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      'Apolo の当店へようこそ！何かお探しですか？お気軽にご相談ください。';

  @override
  String get businessSwitchPleaseEnterStoreNameAt => 'ショップ名を2文字以上で入力してください。';

  @override
  String get businessSwitchPleaseEnterStoreName => 'ショップ名を入力してください。';

  @override
  String get businessSwitchBusinessProfileUpdated => 'Business プロフィールを更新しました！';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      '認証済み Business ショップが公開されました！';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'Business プロフィールを保存できませんでした。もう一度お試しください。';

  @override
  String get businessSwitchBusinessSettings => 'Business 設定';

  @override
  String get businessSwitchSwitchBusiness => 'Business に切り替え';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      '以前のショップ情報をすぐに再開できます！';

  @override
  String get savingLabel => '保存中...';

  @override
  String get businessSwitchSaveChanges => '変更を保存';

  @override
  String get businessSwitchActivateFreeBusiness => '無料 Business を有効化';

  @override
  String get businessSwitchWhatBestDescribesBusiness => 'お店のジャンルに最も近いものはどれですか？';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'このカテゴリーバッジはプロフィールとショップページの名前の下に表示されます。';

  @override
  String get businessSwitchStoreIdentityHoursLocation => 'ショップ情報・営業時間・所在地';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      '公開中の出品が1件以上あると、ショップ一覧に掲載されます。';

  @override
  String get businessSwitchStoreName => 'ショップ名 *';

  @override
  String get businessSwitchEGAutoCasa => '例: Auto Casa';

  @override
  String get businessSwitchBioDescription => 'ショップ紹介・説明';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      '取扱商品やサービスの特徴をお客様に紹介しましょう...';

  @override
  String get businessSwitchCityAddress => '都市・住所';

  @override
  String get businessSwitchEGMaarifCasablanca => '例: Maarif, Casablanca';

  @override
  String get businessSwitchGoogleMapsLinkOptional => 'Google Maps リンク（任意）';

  @override
  String get businessSwitchWorkingHours => '営業時間';

  @override
  String get businessSwitchContactDirectOrderTools => '連絡先＆ダイレクト注文機能';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'ワンタップ注文とチャットの自動あいさつメッセージを設定できます。';

  @override
  String get businessSwitchBusinessPhone => '店舗用電話番号';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      'ショップに「ダイレクト注文」ボタンを表示';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'お客様情報付きの注文をすぐに受け取れます。';

  @override
  String get businessSwitchAutoGreetingMessageChat => 'チャットの自動あいさつメッセージ';

  @override
  String get businessSwitchWelcomeStoreHowCanWe => 'ご来店ありがとうございます！お気軽にご質問ください。';

  @override
  String get callIncomingVideoCall => 'ビデオ通話の着信中...';

  @override
  String get callIncomingVoiceCall => '音声通話の着信中...';

  @override
  String get callRinging => '呼び出し中...';

  @override
  String get callAllowMicCameraAccess => 'マイクとカメラへのアクセスを許可';

  @override
  String get callConnecting => '接続中...';

  @override
  String get callCalls => '通話';

  @override
  String get callCallsAreUnavailableThisDevice => 'この端末では通話機能をご利用いただけません';

  @override
  String get callBackChat => 'チャットに戻る';

  @override
  String get callVideoCall => 'ビデオ通話';

  @override
  String get callVoiceCall => '音声通話';

  @override
  String get callDecline => '拒否';

  @override
  String get callAccept => '応答';

  @override
  String get callMic => 'マイク';

  @override
  String get callCamera => 'カメラ';

  @override
  String get callEnd => '終了';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return '最終メッセージ $lastTime';
  }

  @override
  String get chatListUnpinChat => 'ピン留めを解除';

  @override
  String get chatListPinChat => 'チャットをピン留め';

  @override
  String get chatListChatUnpinned => 'ピン留めを解除しました';

  @override
  String get chatListChatPinnedTop => 'チャットを上部にピン留めしました';

  @override
  String get chatListMarkAsRead => '既読にする';

  @override
  String get chatListUnmuteNotifications => '通知ミュートを解除';

  @override
  String get chatListMuteNotifications => '通知をミュート';

  @override
  String get chatListNotificationsUnmuted => '通知ミュートを解除しました';

  @override
  String get chatListChatMuted => 'チャットをミュートしました';

  @override
  String get chatListArchiveChat => 'アーカイブする';

  @override
  String get chatListChatArchived => 'チャットをアーカイブしました';

  @override
  String get chatListReportChat => 'チャットを通報';

  @override
  String chatListBlockPeername(Object peerName) {
    return '$peerName をブロック';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return '$peerName をブロックしました';
  }

  @override
  String get chatListDeleteChat => 'チャットを削除';

  @override
  String get chatListChatDeleted => 'チャットを削除しました';

  @override
  String get chatListSelectConversationStartMessaging =>
      'チャットを選択してメッセージを始めましょう';

  @override
  String get chatListChats => 'チャット';

  @override
  String get chatListMarkAllRead => 'すべて既読にする';

  @override
  String get searchTitle => '検索';

  @override
  String get chatListAll => 'すべて';

  @override
  String get chatListUnread => '未読';

  @override
  String get chatListPinned => 'ピン留め';

  @override
  String get chatListSignViewChats => 'ログインしてチャットを確認';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      '購入者・出品者と直接、あんしんしてやり取りできます。';

  @override
  String get signInButton => 'ログイン';

  @override
  String get chatListNoUnreadChats => '未読のチャットはありません';

  @override
  String get chatListNoPinnedChats => 'ピン留めしたチャットはありません';

  @override
  String get chatListNoChatsYet => 'まだチャットはありません';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      '気になる出品を見つけて、出品者に直接メッセージを送ってみましょう。';

  @override
  String get chatListExploreListings => '出品をさがす';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      '個人間のメッセージはエンドツーエンドで暗号化されています';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'メッセージを読み込めませんでした。もう一度お試しください。';

  @override
  String get chatRoomMessageEdited => 'メッセージを編集しました';

  @override
  String get chatRoomDeletedEveryone => '全員の画面から削除しました';

  @override
  String get chatRoomMessagePinned => 'メッセージをピン留めしました';

  @override
  String get chatRoomMessageUnpinned => 'ピン留めを解除しました';

  @override
  String get chatRoomMessageStarred => 'スターを付けました ⭐';

  @override
  String get chatRoomStarRemoved => 'スターを外しました';

  @override
  String get chatRoomReportConversation => 'このやり取りを通報';

  @override
  String get chatRoomUserUnblocked => 'ブロックを解除しました';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return '$peerName のブロックを解除';
  }

  @override
  String get chatRoomReply => '返信';

  @override
  String get chatRoomUnpin => 'ピン解除';

  @override
  String get chatRoomPin => 'ピン留め';

  @override
  String get chatRoomUnstar => 'スター解除';

  @override
  String get chatRoomStar => 'スター';

  @override
  String get chatRoomCopied => 'コピーしました';

  @override
  String get editButton => '編集';

  @override
  String get reportButton => '通報';

  @override
  String get deleteButton => '削除';

  @override
  String get chatRoomDeleteEveryone => '全員に対して削除';

  @override
  String get chatRoomMorocco => 'モロッコ';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 現在地: $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 「$title」への値下げオファー: DH $cleaned';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 価格オファー: DH $cleaned';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      '音声を録音できませんでした。マイクの許可設定を確認してもう一度お試しください。';

  @override
  String get chatRoomVoiceMessageIsTooLong => 'ボイスメッセージが長すぎます。もう少し短く録音してください。';

  @override
  String get chatRoomThisMessageWasDeleted => 'このメッセージは削除されました';

  @override
  String get chatRoomRead => '既読';

  @override
  String get chatRoomDelivered => '送信済み';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return '最終オンライン $clock';
  }

  @override
  String get chatRoomOffline => 'オフライン';

  @override
  String get chatRoomVideoCallUnavailable => 'ビデオ通話 — 利用不可';

  @override
  String get chatRoomVoiceCallUnavailable => '音声通話 — 利用不可';

  @override
  String get chatRoomSafetyReport => '安全対策・通報';

  @override
  String get chatRoomYouBlockedThisUser => 'このユーザーをブロックしています';

  @override
  String get chatRoomUnblock => 'ブロック解除';

  @override
  String get chatRoomEditingMessage => 'メッセージを編集中';

  @override
  String get chatRoomSendMessage => 'メッセージを送る';

  @override
  String get editProfileMinimum3CharactersRequired => '3文字以上で入力してください';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return '@$clean は利用可能です';
  }

  @override
  String get editProfileAlreadyTaken => 'すでに使用されています。';

  @override
  String get editProfileProfilePhoto => 'プロフィール写真';

  @override
  String get editProfileChooseFromLibrary => 'ライブラリから選択';

  @override
  String get editProfileTakePhoto => '写真を撮る';

  @override
  String get editProfileRemoveCurrentPhoto => '現在の写真を削除';

  @override
  String get editProfileChoosePresetAvatar => 'またはプリセットアバターを選択';

  @override
  String get editProfileSelectCity => '都市を選択';

  @override
  String get clearButton => 'クリア';

  @override
  String get editProfilePhoneWhatsapp => '電話番号・WhatsApp';

  @override
  String get confirmButton => '確認';

  @override
  String get editProfileNameIsRequired => 'お名前は必須です。';

  @override
  String get editProfileUsernameMustBeAtLeast => 'ユーザー名は3文字以上で入力してください。';

  @override
  String get editProfileThisUsernameIsAlreadyTaken => 'このユーザー名はすでに使われています。';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      '変更を保存できませんでした。もう一度お試しください。';

  @override
  String get editProfileTitle => 'プロフィール編集';

  @override
  String get editProfileEditPicture => '写真を変更';

  @override
  String get editProfileFullName => 'お名前（フルネーム）';

  @override
  String get editProfileUsername => 'ユーザー名';

  @override
  String get editProfileBio => '自己紹介';

  @override
  String get editProfileWriteShortBioAboutYourself => '簡単な自己紹介を書いてみましょう...';

  @override
  String get editProfileAddCity => '都市を追加';

  @override
  String get editProfilePhone => '電話番号';

  @override
  String get editProfileAddPhoneNumber => '電話番号を追加';

  @override
  String get editProfileManageStoreDetails => 'ショップ情報を管理';

  @override
  String get editProfileGetVerifiedBusinessStore => '認証バッジ＆Business ショップを取得';

  @override
  String get editProfilePersonalInformation => '個人情報';

  @override
  String get editProfileEmailPasswordSettings => 'メール・パスワード設定';

  @override
  String get saveChangesButton => '変更を保存';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return '$masked に6桁の認証コードを送信しました。';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      '6桁の認証コードを入力してください。';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      'パスワードを更新し、ログインしました！';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      '新しいパスワードを設定するためのメールをお送りします';

  @override
  String get forgotPasswordChooseNewPassword => '新しいパスワードを設定';

  @override
  String get homeInternetConnectionLost => 'インターネット接続が切断されました';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      '通信環境をご確認のうえ、もう一度出品を読み込んでください。';

  @override
  String get tryAgainButton => 'もう一度試す';

  @override
  String get homeWelcomeApolo => 'Apolo へようこそ';

  @override
  String get homeSearchCarsHomesPhonesAccounts => '車・住まい・スマホ・アカウントを検索...';

  @override
  String get homeLatestListings => '新着の出品';

  @override
  String get homeSeeAll => 'すべて見る';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return '$s から $zoneRadiusKm km 以内の出品はまだありません';
  }

  @override
  String get homeShowAllMorocco => 'モロッコ全体を表示';

  @override
  String get homeChangeZone => 'エリアを変更';

  @override
  String get homeBrowseAllListingsMorocco => 'モロッコ全国の出品を見る';

  @override
  String get home1MarketplaceMorocco => 'モロッコ No.1 マーケットプレイス 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen => '仲介なしで安全・かんたんに売り買い';

  @override
  String get homeCarsPhonesRealEstateDiscover => '車・スマホ・不動産まで、近くの出品をすぐに見つけよう。';

  @override
  String get homeExclusiveDeals => '限定のお得な出品';

  @override
  String get homeWhyChooseApolo => 'Apolo が選ばれる理由';

  @override
  String get home0CommissionFree => '手数料 0%・完全無料';

  @override
  String get homeBuySellFreeZeroMiddlemen => '仲介手数料ゼロで、誰でも無料で売り買いできます。';

  @override
  String get homeDirectChatCall => '直接チャット＆通話';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      '出品者に直接メッセージや値下げ交渉をワンタップで送信。';

  @override
  String get homeVerifiedListings => 'あんしんの出品チェック';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      '安全な取引を守るため、常時パトロールを実施しています。';

  @override
  String get homeGotSomethingSellPostNow => '売りたいものがありますか？今すぐ出品';

  @override
  String get homePublishFree30SecondsGet => 'わずか30秒で無料出品。購入希望者からすぐに連絡が届きます';

  @override
  String get homePost => '出品 +';

  @override
  String get homeVerifiedOfficialStores => '認証済み公式ショップ';

  @override
  String get homeBrowseDealsFromCertifiedStores => '認定ショップや正規取扱店のお得な商品をチェック';

  @override
  String get intentOnboardingWhatWillYouUseApolo => 'Apolo をどのように\n使いたいですか？';

  @override
  String get mainShellYouHaveNewApoloNotification => 'Apolo から新着通知があります';

  @override
  String get mainShellBrowse => 'さがす';

  @override
  String get notificationsEnableNotifications => '通知をオンにする';

  @override
  String get notificationsAreBlocked => '通知がオフになっています';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      '端末またはブラウザの設定から通知を許可し、もう一度「次へ」をタップしてください。';

  @override
  String get notificationsGotIt => 'OK';

  @override
  String get notificationsNotificationPreferences => '通知設定';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      '受け取りたい Apolo の通知を選択してください';

  @override
  String get notificationsMessagesBuyerOffers => 'メッセージ＆価格オファー';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      '購入希望者からメッセージやオファーが届いたらすぐにお知らせ';

  @override
  String get notificationsPriceDropsSavedListings => '値下げ＆お気に入り出品';

  @override
  String get notificationsUpdatesListingsYouBookmarked => '保存した出品の値下げや更新情報をお届け';

  @override
  String get notificationsOfficialStoresUpdates => '公式ショップ＆新着情報';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'フォロー中の認証済み出品者からの新着商品をお知らせ';

  @override
  String get notificationsMarkAllAsRead => 'すべて既読にする';

  @override
  String get doneButton => '完了';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      '続行するには通知を許可してください';

  @override
  String get notificationsActivatedInstantAlerts => 'が次の即時通知をオンにしました：';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — 購入者メッセージ＆オファー';

  @override
  String get notificationsJustNow => 'たった今';

  @override
  String get notificationsApoloTeam => 'Apolo チーム';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      'からのヒント：明るい鮮明な写真を追加すると、取引がより早く決まります。';

  @override
  String get notifications2hAgo => '2時間前';

  @override
  String get notificationsApoloOfficialStores => 'Apolo 公式ショップ';

  @override
  String get notificationsUpdated => 'が更新しました：';

  @override
  String get notificationsVerifiedCarsRealEstateTech => '認証済みの車・不動産・デジタル機器の出品';

  @override
  String get notificationsAcrossAllMoroccanCities => '（モロッコ全都市）';

  @override
  String get notificationsThisWeek => '今週';

  @override
  String get notificationsNotifications => 'お知らせ';

  @override
  String get notificationsHeyItSApolo => 'こんにちは、Apolo です！';

  @override
  String get notificationsIAmReadyHelpYou => 'いつでもサポートします。掘り出し物を探してみませんか？';

  @override
  String get notificationsNow => '今';

  @override
  String get notificationsNotification => '通知';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'メッセージを受け取るには通知をオンにしてください';

  @override
  String get notificationsUpdates => '新着情報';

  @override
  String get notificationsNoNotificationsThisCategory => 'このカテゴリーの通知はありません';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      '購入者からのメッセージ、オファー、出品の更新情報がここに表示されます。';

  @override
  String get notificationsNoInternetConnection => 'インターネットに接続されていません';

  @override
  String get notificationsCheckWiFiMobileData =>
      'Wi-Fi またはモバイルデータ通信を確認して、通知を更新してください。';

  @override
  String get notificationsToday => '今日';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'GPSで現在地を取得できませんでした — 都市を選択してください';

  @override
  String get postAdPleaseSelectCategoryCity => 'カテゴリーと都市を選択してください';

  @override
  String get postAdAddAtLeastOnePhoto => '出品の写真を1枚以上追加してください';

  @override
  String get postAdEnterClearTitleAtLeast => 'わかりやすい商品名を入力してください（3文字以上）';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      '有効な価格または「無料」を設定し、電話番号を認証してください';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return '1日の無料出品上限に達しました（$maxDailyFreeAds件/日）';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return '個人アカウントでは1日最大$maxDailyFreeAds件まで無料で出品できます。Apolo Premium（Google Pay で月額 $monthlyPremiumPriceMad MAD）にアップグレードすると、毎日の出品が無制限になり、Business ショップと認証バッジをご利用いただけます。';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return '登録する（月額 $monthlyPremiumPriceMad MAD）• Google Pay';
  }

  @override
  String get postAdMaybeLater => 'あとにする';

  @override
  String get postAdPleaseSignPublishListing => '出品を公開するにはログインしてください';

  @override
  String get postAdAvailableGreatConditionApolo => 'Apolo にて状態良好で出品中です';

  @override
  String get postAdFailedPublishListing => '出品を公開できませんでした';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'カテゴリーと都市を取得できませんでした。再試行';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium => '毎日の出品が無制限・Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return '本日の上限 $maxDailyFreeAds/$maxDailyFreeAds2件に達しました・アップグレード ($monthlyPremiumPriceMad MAD)';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return '本日: 無料出品 $todayPostedAdsCount/$maxDailyFreeAds件・Premium なら無制限';
  }

  @override
  String get postAdWhereAreYouListing => 'どこで出品しますか？';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      '近くの購入者が見つけやすいよう、カテゴリーと都市を選択してください';

  @override
  String get postAdAddClearPhotos => 'わかりやすい写真を追加';

  @override
  String get postAdListingsRealClearPhotosSell => '実物の明るい写真がある出品は最大3倍早く売れます';

  @override
  String get postAdDescribeItem => '商品の詳細を入力';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'わかりやすいタイトルと丁寧な説明が購入者の安心につながります';

  @override
  String get postAdSetPriceContact => '価格と連絡先の設定';

  @override
  String get postAdSetFairPriceReviewListing => '適正な価格を設定し、公開前に内容を確認しましょう';

  @override
  String get postAdGpsLocationSet => 'GPS位置情報を設定済み';

  @override
  String get postAdDetectAdLocationGps => '現在地を取得 (GPS)';

  @override
  String get postAdTapAddPhotos => 'タップして写真を追加';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return '写真を追加 ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed => '1枚目の写真がメイン画像（カバー）になります';

  @override
  String get postAdGallery => 'ギャラリー';

  @override
  String get postAdSelectedPhotos => '選択した写真';

  @override
  String get postAdCover => 'カバー';

  @override
  String get postAdListingTitle => '商品名・タイトル';

  @override
  String get postAdGreat => 'バッチリ ✓';

  @override
  String get postAdEGIphone15Pro => '例：iPhone 15 Pro Max 256GB 未使用に近い';

  @override
  String get postAdDetailedDescription => '商品の詳しい説明';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      '商品の状態、付属品、購入時期などの詳細を記入してください...';

  @override
  String get postAdSpecifications => 'スペック・詳細情報';

  @override
  String get postAdPriceMad => '価格 (MAD)';

  @override
  String get postAdEG2500 => '例：2500';

  @override
  String get postAdHideNumber => '電話番号を非公開にする';

  @override
  String get postAdListingPreview => '出品プレビュー';

  @override
  String get postAdPublishNow => '出品する';

  @override
  String get postAdListingUpdated => '出品情報を更新しました';

  @override
  String get postAdListingIsLive => '出品が公開されました！';

  @override
  String get postAdListingIsNowVisibleBuyers => 'Apolo.ma の購入者に向けて出品が公開されました。';

  @override
  String get postAdNewListing => '公開した出品';

  @override
  String get postAdBackHome => 'ホームに戻る';

  @override
  String get postAdPostAnotherListing => '続けて出品する';

  @override
  String get privacyComplianceReportAiPolicyIssue => 'AI・規約違反の問題を通報';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      '安全対策チームが確認するため、通報理由を選択してください：';

  @override
  String get privacyComplianceAdditionalDetailsOptional => '補足事項（任意）...';

  @override
  String get privacyComplianceSubmitReport => '通報を送信';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      '通報を送信できませんでした。もう一度お試しください。';

  @override
  String get privacyComplianceReportSubmittedSuccessfully => '通報を受け付けました ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'リンクをコピーしました: $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion => 'アカウント削除の確認';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      'Apolo からアカウント、個人データ、出品、メッセージを完全に削除してもよろしいですか？この操作は取り消せません。';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get privacyComplianceDeletePermanently => '完全に削除する';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted => 'アカウントとデータを削除しました。';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      '削除を完了できませんでした。ログイン状態は維持されています。もう一度お試しください。';

  @override
  String get privacyCompliancePrivacyPolicies => 'プライバシーと規約';

  @override
  String get privacyCompliancePrivacy => 'プライバシー';

  @override
  String get privacyCompliancePolicies => '利用規約';

  @override
  String get privacyComplianceDataDelete => 'データ・削除';

  @override
  String get privacyComplianceUpdated2026Law0908 => '2026年改定・法律 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl => 'プライバシーはあなた自身で管理できます';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      '当社が個人データを販売することは一切ありません。お預かりした情報は Apolo (ma.apolo.apoloMobile) での出品掲載、安全なチャット、モバイル通知の提供にのみ使用されます。';

  @override
  String get privacyComplianceDataWeCollect => '収集するデータ';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• アカウント情報：氏名、メールアドレス、電話番号、または安全な Google / Apple ログイン情報。\n• 出品＆ショップ情報：写真、タイトル、説明文、MAD 価格、選択した都市。\n• リアルタイムメッセージ：購入者と出品者間のチャットメッセージ、画像・音声メディア、絵文字リアクション。\n• プッシュ通知トークン (FCM / APNs)：OS通知の配信にのみ使用され、ログアウト時に自動で無効化されます。';

  @override
  String get privacyComplianceDevicePermissionsControls => '端末の権限と管理';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• 通知：iOS・Android での新着メッセージ通知（任意・いつでも変更可能）。\n• カメラ＆写真：出品写真やチャット添付ファイルをアップロードする際のみ要求されます。\n• おおよそのエリア：都市単位での距離絞り込みのみを行い、バックグラウンドでの GPS 追跡は一切行いません。';

  @override
  String get privacyComplianceAiSafetyAppReporting => 'AIの安全性とアプリ内通報';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'スマート出品・検索機能にはアプリ内通報ボタンが備わっており、不正確なAI提案や不適切な出品をすぐに報告できます。';

  @override
  String get privacyComplianceLegalRightsContact => '法的権利とお問い合わせ窓口';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'モロッコ法 09-08 および App Store / Google Play の規定に基づき、ご自身の個人データへのアクセス、修正、完全削除を求める権利があります。\n• 公式メール：support@apolo.ma / contact@apolo.ma\n• ウェブサイト：https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp => 'AI・規約違反をアプリ内で通報';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy => 'Web版プライバシーポリシーを開く';

  @override
  String get privacyComplianceTermsUseMarketplaceRules => '利用規約＆マーケットプレイスルール';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      '安全に売り買いするための明確なルール';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'Apolo をご利用いただくことで、誠実な出品、丁寧なやり取り、透明性のあるマーケットプレイスルールに同意したものとみなされます。';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'アカウントの信頼性と認証バッジ';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• アカウントおよびショップ情報は常に正確かつ事実に基づいた内容を記載してください。\n• 認証シールや出品者ランク（ブロンズ〜チャンピオン）は Apolo のみが付与します。なりすまし行為は禁止されています。';

  @override
  String get privacyComplianceListingRulesProhibitedItems => '出品ルールと禁止出品物';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• 実在する商品・サービスを実物写真と誠実な価格で出品してください。\n• 禁止出品物：偽ブランド品・模造品、武器類、違法薬物、処方薬、盗品、前払い詐欺などは固く禁じられています。';

  @override
  String get privacyComplianceSafeTransactionsChatConduct => '安全な取引とチャットマナー';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• 人目のある安全な場所で実物を確認してからお支払いください。事前の手付金送金はお控えください。\n• スパム、嫌がらせ、暴言は即時利用停止の対象となります。いつでもブロック・通報が可能です。';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'Pro+ サブスクリプション＆出品ブースト';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• Pro+ プランおよびブースト機能は、App Store または Google Play アカウントを通じて明朗に決済されます。\n• 自動更新は期間終了の24時間前までに各ストアのアカウント設定からいつでも解約できます。';

  @override
  String get privacyComplianceOpenWebTermsPolicies => 'Web版利用規約・ポリシーを開く';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      '即時データ消去・App Store & Google Play 準拠';

  @override
  String get privacyCompliancePermanentAccountDataDeletion => 'アカウントとデータの完全削除';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'アプリ内から直接、または外部のWeb削除フォームからアカウントと関連するすべての個人データを消去できます。';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted => '完全に削除されるデータ';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• プロフィールおよび認証情報（氏名、メールアドレス、電話番号、OAuth連携）。\n• 公開中のすべての出品、アップロードした写真、ショップデータ。\n• チャット履歴、お気に入り一覧、有効なモバイルプッシュ通知トークン。';

  @override
  String get privacyComplianceDeleteMyAccountNowApp => '今すぐアカウントを削除（アプリ内）';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'アプリ内で直接アカウントを削除するにはログインしてください。または下のWeb削除リンクをご利用ください。';

  @override
  String get privacyComplianceExternalWebDataDeletionLink => '外部Webデータ削除フォーム';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      '定期購読（いつでも解約可能）。購入確定時に Google Pay またはストアアカウントに課金され、現在の期間終了の24時間前までにオフにしない限り自動更新されます。\nすべての個人データの取り扱い基準：';

  @override
  String get proPlusTermsConditions => '利用規約';

  @override
  String get proPlusAnd => 'および';

  @override
  String get proPlusPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get proPlusSubscription => 'サブスクリプション';

  @override
  String get proPlusCancelPremiumSubscription => 'Premium サブスクリプションを解約しますか？';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'ショップや出品データを保持したまま、自動更新のみオフになります。';

  @override
  String get proPlusCancelMySubscription => 'サブスクリプションを解約';

  @override
  String get proPlusKeepPremium => 'Premium を続ける';

  @override
  String get proPlusYouUsePremium => 'Premium ご利用中';

  @override
  String get proPlusGetPremium => 'Premium に登録';

  @override
  String get proPlusYouHaveUnlimitedAccessAll => 'すべてのプレミアム機能を無制限でご利用いただけます';

  @override
  String get proPlusGetUnlimitedAccessAllPremium => 'すべてのプレミアム機能を無制限で使おう';

  @override
  String get proPlusCheckedAccountActivePurchases => 'アカウントの有効な購入履歴を確認しました。';

  @override
  String get proPlusHowTrialWorks => '無料トライアルの流れ';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return '3日間すべての機能が使い放題、その後は Google Pay で月額わずか $monthlyPremiumPriceMad MAD';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      '今すぐ全機能を体験して、Pro Plus で売上アップを実感してください。';

  @override
  String get proPlusDay2 => '2日目';

  @override
  String get proPlusWeLlRemindYouNotification => 'トライアル終了前に通知でお知らせします。';

  @override
  String get proPlusDay3 => '3日目';

  @override
  String get proPlusYouLlBeChargedDay => '3日目に課金が開始されます。それ以前はいつでも無料で解約可能です。';

  @override
  String get proPlusViewAllPlans => 'すべてのプランを見る';

  @override
  String get proPlusRestorePurchases => '購入を復元';

  @override
  String get proPlusStartFree3DayTrial => '3日間の無料トライアルを始める';

  @override
  String get proPlusPaymentVerificationFailed => 'お支払いの確認に失敗しました。';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      'Pro Plus が有効になりました！ショップが認証済みになりました';

  @override
  String get proPlusCouldNotLaunchGooglePay => 'この端末で Google Pay を起動できませんでした。';

  @override
  String get proPlusPayGooglePay => 'Google Pay で支払う';

  @override
  String get proPlusSave25 => '25% お得';

  @override
  String get proPlusLifetime => '買い切り（永久）';

  @override
  String get proPlusBasic => 'ベーシック';

  @override
  String get proPlus12Months => '12ヶ月';

  @override
  String get proPlusOneTime => '1回払い';

  @override
  String get proPlus1Month => '1ヶ月';

  @override
  String get proPlusMad => 'MAD';

  @override
  String get proPlusPaywall => 'プラン選択';

  @override
  String get proPlusUnlockFullAccess => 'すべての機能をアンロック';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'すべての機能とテンプレートが無制限で使えます';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      '公式 Business ショップ＋ブルー認証バッジ';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      '1日の出品数が無制限（通常5件/日）＋写真12枚まで掲載';

  @override
  String get proPlus5FreeMonthlyVipBoosts => '毎月5回の無料 VIP ブースト＋Pro分析＆クイック返信';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return '$priceDisplay MAD で登録 • Google Pay';
  }

  @override
  String get proPlusNoThankYou => '今はしない';

  @override
  String get profileCouldNotLoadListingsPull =>
      '出品を読み込めませんでした。下に引っ張って再試行してください。';

  @override
  String get profileMyAccount => 'マイアカウント';

  @override
  String get profileSettingsSupport => '設定＆サポート';

  @override
  String get profileSignManageListingsSavedItems =>
      'ログインして出品の管理、お気に入り、チャットを利用しましょう。';

  @override
  String get profileSignViewProfile => 'ログインしてマイページを表示';

  @override
  String get welcomeCreateAccountButton => 'アカウントを作成';

  @override
  String get profileLightMode => 'ライトモード';

  @override
  String get profileDarkMode => 'ダークモード';

  @override
  String get profileListings => '出品数';

  @override
  String get profileLikes => 'いいね';

  @override
  String get profileSaved => '保存済み';

  @override
  String get shareProfileButton => 'プロフィールを共有';

  @override
  String get profileMyListings => '出品した商品';

  @override
  String get profileProInsightsBoost => 'Pro分析＆ブースト';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'Apolo Premium にアップグレード・月額 $monthlyPremiumPriceMad MAD';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'Google Pay で Business ショップ＋認証バッジ＋毎日の無制限出品。';

  @override
  String get profileViewStore => 'ショップを見る';

  @override
  String get profileEditStore => 'ショップを編集';

  @override
  String get profileQuickReplies => 'クイック返信';

  @override
  String get profileNoListingsYet => 'まだ出品がありません';

  @override
  String get profilePublishFirstListingShowcaseIt => '最初の商品を出品してここに表示させましょう。';

  @override
  String get profilePostListing => '商品を出品する';

  @override
  String get profileTotalViews => '合計閲覧数';

  @override
  String get profileActiveListings => '公開中の出品';

  @override
  String get profileAvgListing => '1出品あたり平均';

  @override
  String get profileBoostedListings => 'ブースト中の出品';

  @override
  String get profileCallTaps => '通話タップ数';

  @override
  String get profileCustomerChats => 'チャット件数';

  @override
  String get profileDirectOrders => 'ダイレクト注文数';

  @override
  String get profileFreeVipCredits => '無料 VIP クレジット';

  @override
  String get profileUnlockCallOrderStatsPro => '通話・注文データ＋PRO+ バッジを解放';

  @override
  String get profileGet3FreeVipBoosts => '毎月3回の無料 VIP ブーストと優先表示を獲得しよう。';

  @override
  String get profileViewsBreakdown => '閲覧数の内訳';

  @override
  String get profileLive => '公開中';

  @override
  String get profilePublishFirstListingTrackViews =>
      '最初の商品を出品すると、閲覧数やパフォーマンスをここで確認できます。';

  @override
  String get profileTopPerformingListings => '人気の出品トップ';

  @override
  String get profileViews => '回閲覧';

  @override
  String get profileSalesTip => '売れやすくなるコツ';

  @override
  String get profileAddClearPhotosFairPrice =>
      '明るい写真と適正価格を設定すると、購入希望者がすぐに見つかります。';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      '写真の撮り直しや人気商品のブーストで、さらに早く売れやすくなります。';

  @override
  String get profileEditListing => '出品を編集';

  @override
  String get profileBoostThisListing => 'この出品をブースト';

  @override
  String get profileDeleteListing => '出品を削除';

  @override
  String get profileCouldNotDeleteListingPlease => '出品を削除できませんでした。もう一度お試しください。';

  @override
  String get profileDeleteThisListing => 'この出品を削除しますか？';

  @override
  String get profileThisListingWillBePermanently =>
      'この出品はマイページと検索結果から完全に削除されます。';

  @override
  String get profileListingDeletedSuccessfully => '出品を削除しました';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'ご自身のプロフィールです';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'Apolo メンバー #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => '読み取ったコード';

  @override
  String get scanProfileCodeCodeDetected => 'コードを検出しました';

  @override
  String get scanProfileCodeOpenLink => 'リンクを開く';

  @override
  String get scanProfileCodeScanAgain => 'もう一度スキャン';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'このブラウザではライトを使用できません';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'このカメラではライトを使用できません';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight => '現在ライトを切り替えられません';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      '選択した画像から QR コードが見つかりませんでした';

  @override
  String get scanProfileCodeEnterCode => 'コードを入力';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary => 'フォトライブラリを開けませんでした';

  @override
  String get scanProfileCodeScanQrCode => 'QR コードをスキャン';

  @override
  String get scanProfileCodePickQrImage => 'QR 画像を選択';

  @override
  String get scanProfileCodeTapEnableCamera => 'タップしてカメラを有効化';

  @override
  String get scanProfileCodeEnterCodeManually => '手動でコードを入力';

  @override
  String get scanProfileCodePleaseEnterLinkHandle => 'リンクまたはユーザー名を入力してください';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'Apolo のプロフィールリンクを貼り付けるか @handle を入力';

  @override
  String get scanProfileCodeOpenProfile => 'プロフィールを開く';

  @override
  String get searchRecommended => 'おすすめ順';

  @override
  String get searchNewest => '新着順';

  @override
  String get searchLowestPrice => '価格の安い順';

  @override
  String get searchHighestPrice => '価格の高い順';

  @override
  String get searchMostViewed => '閲覧数の多い順';

  @override
  String get searchFilterSort => '絞り込み・並び替え';

  @override
  String get resetButton => 'リセット';

  @override
  String get searchSortBy => '並び替え';

  @override
  String get searchAllMorocco => 'モロッコ全域';

  @override
  String get searchPriceRangeMad => '価格帯 (MAD)';

  @override
  String get searchMinPrice => '下限価格';

  @override
  String get searchMaxPrice => '上限価格';

  @override
  String get searchNegotiableListingsOnly => '値下げ交渉OKのみ';

  @override
  String get searchApplyFilters => 'この条件で絞り込む';

  @override
  String get searchSignSaveSearchesListings => 'ログインして検索条件やお気に入りを保存';

  @override
  String get searchSaved => '検索条件を保存しました';

  @override
  String get searchUnableSaveSearchRightNow => '現在検索条件を保存できません';

  @override
  String get searchSaveSearch => '検索条件を保存';

  @override
  String get searchNoSavedListingsYet => '保存済みの出品はまだありません';

  @override
  String get searchTapHeartAnyListingSave => '気になる出品のハートをタップするとここに保存されます';

  @override
  String get searchFilter => '絞り込み';

  @override
  String get searchAllCategories => 'すべてのカテゴリー';

  @override
  String get searchAllAreas => 'すべてのエリア';

  @override
  String get searchSetArea => 'エリアを設定';

  @override
  String get searchFeedView => 'フィード表示';

  @override
  String get searchGridView => 'グリッド表示';

  @override
  String get personalAccountBadge => '個人';

  @override
  String get businessAccountBadge => 'Business';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return '$s から $zoneRadiusKm km 以内に出品はありません。';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      '別のカテゴリーを試すか、絞り込み条件を広げてみてください。';

  @override
  String get searchResetFilters => '条件をリセット';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable => '出品者の電話番号は公開されていません';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      '出品者にメッセージを送るには、いずれかの出品を選択してください。';

  @override
  String get sellerProfileReportSeller => '出品者を通報';

  @override
  String get sellerProfileBlockSeller => '出品者をブロック';

  @override
  String get sellerProfileSellerBlockedSuccessfully => '出品者をブロックしました';

  @override
  String get sellerProfileFollowers => 'フォロワー';

  @override
  String get sellerProfileRating => '評価';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return '$city の個人出品者・チャットで直接やり取り可能';
  }

  @override
  String get sellerProfileVisitStore => 'ショップを見る';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return '出品 ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return '評価 ($count)';
  }

  @override
  String get sellerProfileTrustInfo => '本人確認・詳細';

  @override
  String get sellerProfileNoListingsAvailableRightNow => '現在公開中の出品はありません';

  @override
  String get sellerProfile3DaysAgo => '3日前';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'とても信頼できる出品者様です。写真通りの綺麗な商品で、やり取りも丁寧でした。';

  @override
  String get sellerProfile1WeekAgo => '1週間前';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      '支払い前に実物をしっかり確認でき、スムーズに購入できました。おすすめです！';

  @override
  String get sellerProfile2WeeksAgo => '2週間前';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      '誠実で親切な出品者さんでした。ノートPCの動作確認も快くさせてくれました。';

  @override
  String get sellerProfile1MonthAgo => '1ヶ月前';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      '安心してお取引できました。Apolo チャットの返信もとても早かったです。';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '認証済みレビュー $count件';
  }

  @override
  String get sellerProfileGovernmentIdVerified => '本人確認書類（公的身分証）確認済み';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'Apolo 安全対策チームが公的本人確認書類を審査・認証済みです。';

  @override
  String get sellerProfileVerifiedPhoneNumber => '電話番号認証済み';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'SMS OTP 認証により電話番号が確認されています。';

  @override
  String get sellerProfileApoloSafetyProtection => 'Apolo あんしん安全ガイド';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'お支払い前に、直接実物の状態をご確認いただくことをおすすめします。';

  @override
  String get sellerProfileAvailableDeliveryMethods => '対応している受け渡し方法';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return '$city での手渡し、または双方合意のうえ補償付き宅配便で発送。';
  }

  @override
  String get accountCenterSwitchPersonalAccount => '個人アカウントに切り替え';

  @override
  String get accountCenterReturnPersonalAccount => '個人アカウントに戻しますか？';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'Business ショップページは一時停止されますが、いつでも再開できます。';

  @override
  String get accountCenterConfirmSwitch => '切り替えを確定';

  @override
  String get accountCenterSwitchedPersonalAccount => '個人アカウントに切り替えました。';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'アカウントの種類を切り替えられませんでした。もう一度お試しください。';

  @override
  String get accountCenterApoloAccount => 'Apolo アカウント';

  @override
  String get accountCenterPersonalDetails => '基本情報';

  @override
  String get accountCenterEmailPhone => 'メール・電話番号';

  @override
  String get accountCenterAccountTypePreferences => 'アカウント種別・設定';

  @override
  String get accountCenterPasswordSecurity => 'パスワードとセキュリティ';

  @override
  String get accountCenterResetPassword => 'パスワードをリセット';

  @override
  String get accountCenterBusinessStore => 'Business・ショップ';

  @override
  String get accountCenterEditStoreProfile => 'ショッププロフィールを編集';

  @override
  String get accountCenterSwitchBusinessAccount => 'Business アカウントに切り替え';

  @override
  String get accountCenterAccountOwnership => 'アカウント管理・削除';

  @override
  String get accountCenterDeleteAccountData => 'アカウントとデータの削除';

  @override
  String get accountCenterManageApoloAccount => 'Apolo アカウントを管理';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'ログインしてセキュリティ、基本情報、ショップを管理しましょう。';

  @override
  String get logInButton => 'ログイン';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully => 'アプリデータを最新に更新しました。';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'データを更新できませんでした。通信環境を確認してもう一度お試しください。';

  @override
  String get settingsAppDataAppDataSync => 'アプリデータと同期';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'システム情報および Apolo.ma との同期ステータス。';

  @override
  String get settingsAppDataApplicationStatus => 'アプリの状態';

  @override
  String get settingsAppDataAppVersion => 'アプリバージョン';

  @override
  String get settingsAppDataServer => 'サーバー';

  @override
  String get settingsAppDataSyncedCategories => '同期済みカテゴリー数';

  @override
  String get settingsAppDataSyncedCities => '同期済み都市数';

  @override
  String get settingsAppDataActiveZone => '設定中のエリア';

  @override
  String get settingsAppDataOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get settingsAppDataRefreshDataNow => '今すぐデータを更新';

  @override
  String get settingsAppearanceAppearance => '外観・テーマ';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'Apolo の画面デザインを選択できます。ライトモード、ダークモード、または端末設定への自動連動から選べます。';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      '明るい場所でも見やすいクリーンな白基調のデザイン';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      '暗い場所でも目に優しく、バッテリー消費も抑えます';

  @override
  String get settingsAppearanceSystemDefault => '端末の設定に合わせる';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'スマホやブラウザのテーマ設定に自動で合わせます';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return '$name のブロックを解除しました';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'ブロック中のアカウント';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet => 'ブロック中のアカウントはありません';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'チャットや出品からブロックしたユーザー・ショップがここに表示され、いつでも解除できます。';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser => 'ブロックはいつでも解除できます。';

  @override
  String get settingsBlockedAccountsBlockedStore => 'ブロック中のショップ';

  @override
  String get settingsBlockedAccountsBlockedUser => 'ブロック中のユーザー';

  @override
  String get settingsBugReportQuickTrigger => 'クイック起動';

  @override
  String get settingsBugReportDiagnosticsSummary => '診断情報の概要';

  @override
  String get settingsBugReportPlatform => 'プラットフォーム';

  @override
  String get settingsBugReportActiveLanguage => '表示言語';

  @override
  String get settingsBugReportHelpSupport => 'ヘルプ＆サポート';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      '言語設定を保存できませんでした。もう一度お試しください。';

  @override
  String get settingsLanguageAppLanguage => 'アプリの言語';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'アプリの画面と出品表示に使用する言語を選択します。変更はすぐに反映されます。';

  @override
  String get settingsRateAppNeedsWork => '改善が必要';

  @override
  String get settingsRateAppFair => 'まあまあ';

  @override
  String get settingsRateAppGreat => '良い';

  @override
  String get settingsRateAppAwesome => '最高！';

  @override
  String get settingsRateAppSelectStars => '星を選択してください';

  @override
  String get settingsRateAppPleaseSelect15Stars => '星1〜5つを選択してください。';

  @override
  String get settingsRateAppRateApp => 'アプリを評価';

  @override
  String get settingsRateAppHowIsExperienceApoloMa => 'Apolo.ma の使い心地はいかがですか？';

  @override
  String get settingsRateAppAddQuickNoteOptional => 'ひとこと感想を添える（任意）...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return '$rating/5 のご評価ありがとうございます！';
  }

  @override
  String get settingsRateAppSubmitRating => '評価を送信';

  @override
  String get settingsRateAppVisitApoloMa => 'Apolo.ma を開く';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'お気に入りから削除できませんでした。もう一度お試しください。';

  @override
  String get settingsSavedAdsSignViewSavedListings => 'ログインして保存済みの出品を見る';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      '気になる出品を保存して、いつでも見返せます。';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings => '保存済みの出品を読み込めませんでした';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'インターネット接続を確認してもう一度お試しください。';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      '出品のお気に入りアイコンをタップするとここに保存されます。';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'モロッコのフリマ＆公式ショップマーケット Apolo.ma をチェックしよう: $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'アプリをシェア';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      '個人間フリマも公式ショップも揃うモロッコのマーケットプレイス。家族や友だちにシェアしよう。';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'アプリのリンクをコピーしました: $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => '今すぐ共有';

  @override
  String get settingsShareAppCopyLink => 'リンクをコピー';

  @override
  String get settingsShareAppShareMyQrProfile => 'マイ QR プロフィールを共有';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'ご意見・ご要望を5文字以上で入力してください。';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      '現在ネットワーク経由で送信できませんでした。再試行するかメールでお送りください。';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'support@apolo.ma をコピーしました';

  @override
  String get settingsSuggestionFeature => '新機能';

  @override
  String get settingsSuggestionDesign => 'デザイン';

  @override
  String get settingsSuggestionPerformance => '動作・速度';

  @override
  String get settingsSuggestionOther => 'その他';

  @override
  String get settingsSuggestionMakeSuggestion => '改善アイデアを送る';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'Apolo.ma をもっと良くするためのアイデアをお聞かせください。';

  @override
  String get settingsSuggestionTopic => 'カテゴリー';

  @override
  String get settingsSuggestionYourSuggestion => 'ご意見・アイデア';

  @override
  String get settingsSuggestionWriteIdeaHere => 'アイデアをここに入力してください...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      'ありがとうございます！ご意見を受け付けました。';

  @override
  String get settingsSuggestionSubmitSuggestion => 'アイデアを送信';

  @override
  String get settingsSuggestionEmailSupportApoloMa => 'support@apolo.ma にメールする';

  @override
  String get settingsZoneMarketplaceZone => '表示エリア設定';

  @override
  String get logOutButton => 'ログアウト';

  @override
  String get settingsLogOutAccount => 'アカウントからログアウトしますか？';

  @override
  String get settingsYouCanSignBackAnytime => 'いつでも再ログインして出品やメッセージを確認できます。';

  @override
  String get settingsProActive => 'PRO+ 利用中';

  @override
  String get settingsNotSubscribed => '未登録';

  @override
  String get settingsVipBoostCredits => 'VIP ブースト残数';

  @override
  String get settingsPrivacyTerms => 'プライバシーと利用規約';

  @override
  String get settingsAppDataLicenses => 'アプリデータとライセンス';

  @override
  String get settingsActivity => '設定とアクティビティ';

  @override
  String get settingsNoMatchingSettings => '一致する設定が見つかりません';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      '「保存済み」「言語」「Pro+」など別のキーワードでお試しください。';

  @override
  String get settingsYourAccount => 'アカウント';

  @override
  String get settingsHowYouUseApolo => 'Apolo の利用設定';

  @override
  String get settingsSubscriptions => 'サブスクリプション';

  @override
  String get settingsCommunityPrivacy => 'コミュニティとプライバシー';

  @override
  String get settingsSupport => 'サポート';

  @override
  String get settingsAccount => 'アカウント管理';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'パスワード、セキュリティ、個人情報、ショップ＆Business';

  @override
  String get shareProfileProfileLinkCopied => 'プロフィールリンクをコピーしました';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'Apolo.ma で $name ($handle) さんをチェック:\n$url';
  }

  @override
  String get shareProfileShareLink => 'リンクを共有';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'QR コードは非公開です。共有した相手がカメラでスキャンすると、あなたを連絡先に追加できます。';

  @override
  String get shareProfileScanCode => 'コードをスキャン';

  @override
  String get storeDetailReportStore => 'ショップを通報';

  @override
  String get storeDetailStoreBlocked => 'ショップをブロックしました';

  @override
  String get storeDetailBlockStore => 'ショップをブロック';

  @override
  String get storeDetailDirectStoreOrder => 'ショップダイレクト注文';

  @override
  String get storeDetailSelectItem => '商品を選択';

  @override
  String get storeDetailFullName => 'お名前（フルネーム）';

  @override
  String get storeDetailDeliveryAddress => 'お届け先住所';

  @override
  String get storeDetailOrderNotes => '注文メモ・ご要望';

  @override
  String get storeDetailConfirmOrder => '注文を確定する';

  @override
  String get storeDetailOrderSubmittedSuccessfully => '注文を送信しました';

  @override
  String get storeDetailStoreNotFound => 'ショップが見つかりません';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'リンクを確認するか、認証済みショップ一覧をご覧ください。';

  @override
  String get storeDetailOrderNow => '今すぐ注文';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return '営業中 · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return '営業時間外 · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'Google Maps で開く';

  @override
  String get storeDetailOrder => '注文する';

  @override
  String get storeDetailProducts => '商品数';

  @override
  String get verifiedBadgeLabel => '認証済み';

  @override
  String get storeDetailDelivery => '配送';

  @override
  String get storeDetailStoreCatalog => 'ショップ商品一覧';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '認証済み公式ショップ $totalStores店';
  }

  @override
  String get storesSearchOfficialStores => '公式ショップを検索...';

  @override
  String get storesMostProducts => '商品数が多い順';

  @override
  String get storesTopRated => '評価が高い順';

  @override
  String get storesNoMatchingStores => '該当するショップがありません';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      '別のキーワードを試すか、認証済みショップ一覧を再読み込みしてください。';

  @override
  String get storesItems => '点';

  @override
  String get storesVisit => 'ショップへ';

  @override
  String get supportCouldNotOpenMailApp =>
      'メールアプリを開けませんでした。お手数ですが support@apolo.ma 宛に直接メールをお送りください。';

  @override
  String get supportHowCanWeHelpYou => 'お困りですか？';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      '発生している問題とそれまでの操作手順をご記入ください。個人情報を隠したスクリーンショットを添付することもできます。';

  @override
  String get supportDirectContact => '直接お問い合わせ';

  @override
  String get supportOpenMailApp => 'メールアプリを開く';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'メールが自動送信されることはありません。メールアプリで内容をご確認のうえ送信してください。';

  @override
  String get supportSafetyReminder => '安全のためのご注意';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'パスワード、認証コード、お支払い情報は誰にも教えないでください。';

  @override
  String get welcomeUnableStartGoogleSignRight => '現在 Google ログインを開始できません。';

  @override
  String get welcomeContinueGoogle => 'Google で続ける';

  @override
  String get welcomeOr => 'または';

  @override
  String get welcomeIHaveAccount => 'すでにアカウントをお持ちの方';

  @override
  String get welcomeNewOfferReceivedListing => '出品した商品に新しいオファーが届きました！';

  @override
  String get welcomeY => 'Y';

  @override
  String get welcomeYassineCasablanca => 'Yassine • Casablanca';

  @override
  String get welcomeYesAvailableWelcome => 'はい、まだ在庫あります！よろしくお願いします。';

  @override
  String get accommodationCardSintraPortugal => 'Sintra, Portugal';

  @override
  String get accommodationCardExclusiveDeal => '限定プラン';

  @override
  String get adCardVip => 'VIP';

  @override
  String get safetyReportMessage => 'メッセージを通報';

  @override
  String get safetyReportListing => '出品を通報';

  @override
  String get safetyReportUser => 'ユーザーを通報';

  @override
  String get safetyAlsoBlockThisAccount => 'このアカウントも同時にブロックする';

  @override
  String get safetySubmitReport => '通報を送信';

  @override
  String get safetyReportSubmittedSuccessfully => '通報を受け付けました';

  @override
  String get safetyBlockedAccounts => 'ブロック中のアカウント';

  @override
  String get boostCouldNotCompletePayment => 'お支払いを完了できませんでした';

  @override
  String get boostListingBoosted => '出品をブーストしました！';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'お支払いが確認できませんでした。再試行する前にサポートへお問い合わせください。';

  @override
  String get boostVipBoostActivatedUsingPro =>
      'Pro+ クレジットを使って VIP ブーストを有効にしました！';

  @override
  String get boostListing => '出品をブーストする';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'Pro+ で無料 VIP を有効化 ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts => 'Apolo Pro+ で毎月3回の無料 VIP ブーストを獲得';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      '現在プランを読み込めません。しばらくしてからもう一度お試しください。';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'お使いのアカウントでは即時Web決済をご利用いただけます。';

  @override
  String get boostActivateBoostNow => '今すぐブーストを有効化';

  @override
  String get chatUtilsYesterday => '昨日';

  @override
  String get guestFavoriteBadge => 'ゲストに人気';

  @override
  String get exploreListingCardContactSeller => '出品者に連絡';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      '現在地を自動取得できませんでした — 下から都市を選択してください';

  @override
  String get marketplaceZoneMarketplaceLocation => '検索エリア';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal => '指定したエリア内の出品のみを表示します';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress => '地域・都市・住所を検索...';

  @override
  String get marketplaceZoneNationwide => '全国';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically => '現在地を自動で取得する';

  @override
  String get marketplaceZoneDistanceRadius => '検索範囲（半径）';

  @override
  String get marketplaceZoneAllMorocco => 'モロッコ全域';

  @override
  String get marketplaceZoneSelectCity => '都市を選択';

  @override
  String get marketplaceZoneApplyZone => 'エリアを適用';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return '上限（$maxAllowed件）に達しました。Pro Plus にアップグレードして枠を増やしましょう！';
  }

  @override
  String get quickRepliesQuickRepliesSaved => 'クイック返信を保存しました ⚡';

  @override
  String get quickRepliesChatQuickReplies => 'チャットのクイック返信';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'チャット画面でショートカットをタップするだけで、購入者にワンタップ返信できます。';

  @override
  String get quickRepliesAddQuickReply => 'クイック返信を追加';

  @override
  String get quickRepliesLabel => 'ラベル';

  @override
  String get quickRepliesReplyText => '返信メッセージを入力...';

  @override
  String get quickRepliesAutoGreetingMessage => '自動あいさつメッセージ';

  @override
  String get quickRepliesWelcomeStore => 'ご来店ありがとうございます！';

  @override
  String get quickRepliesSaveQuickReplies => 'クイック返信を保存';

  @override
  String get quickRepliesManage => '管理';

  @override
  String get realMarketplaceMapApproximateMapArea => 'おおよそのマップ範囲';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return '現在地から $distKm km';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'マイエリアに設定';

  @override
  String get badgesKitBronze => 'ブロンズ';

  @override
  String get badgesKitSilver => 'シルバー';

  @override
  String get badgesKitGold => 'ゴールド';

  @override
  String get badgesKitPlatinum => 'プラチナ';

  @override
  String get badgesKitDiamond => 'ダイヤモンド';

  @override
  String get badgesKitChampion => 'チャンピオン';

  @override
  String get badgesKitStarterMemberApolo => 'Apolo スターターメンバー';

  @override
  String get badgesKitVerifiedAccount2Listings => '認証済みアカウント、または2件以上の出品';

  @override
  String get badgesKitBusinessStore5Listings => 'Business ショップ、または5件以上の出品';

  @override
  String get badgesKitActiveProActiveStore8 => '有効な Pro+ またはアクティブなショップ（8件以上）';

  @override
  String get badgesKitPro10Listings1500 => 'Pro+ かつ出品10件以上または閲覧数1,500回以上';

  @override
  String get badgesKitTopTierPro20Listings =>
      '最高ランク：Pro+ かつ出品20件以上または閲覧数5,000回以上';

  @override
  String get badgesKitSellerRank => '出品者ランク:';

  @override
  String get badgesKitTopRankUnlockedApolo => 'Apolo の最高ランクを達成しました！';

  @override
  String get badgesKitNext => '次のランク:';

  @override
  String get badgesKitTrustSellerRanks => '信頼バッジ＆出品者ランク';

  @override
  String get badgesKitCurrentRank => '現在のランク:';

  @override
  String get badgesKitVerifiedApoloAccount => '認証済み Apolo アカウント';

  @override
  String get badgesKitVerifiedSeal => '認証シール';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      '本人確認と連絡先認証が完了しており、より安全にお取引いただけます。';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      '電話番号認証または Pro ショップの有効化で獲得できます。';

  @override
  String get badgesKitAllSellerRanks => 'すべての出品者ランク';

  @override
  String get badgesKitCurrent => '現在';

  @override
  String get infeedUpgradeCardYourProfile => 'your_profile';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'Apolo Premium に登録して、購入者からの信頼度をアップさせましょう。';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'プロフィールをアップグレード';

  @override
  String get infeedUpgradeCardNotNow => '今はしない';

  @override
  String get searchSuggestionsSearchUsernames => 'ユーザー名を検索';

  @override
  String get searchSuggestionsSuggestions => '候補';

  @override
  String get searchSuggestionsRecentSearches => '最近の検索';

  @override
  String get searchSuggestionsPopularSearches => '人気の検索ワード';

  @override
  String get followedButton => 'フォロー済み';

  @override
  String get writeReviewExcellent => 'とても良い';

  @override
  String get writeReviewVeryGood => '良い';

  @override
  String get writeReviewPoor => '残念';

  @override
  String get writeReviewGreatCommunication => '丁寧なやり取り';

  @override
  String get writeReviewAsDescribed => '説明通りの商品';

  @override
  String get writeReviewFastResponse => '返信が早い';

  @override
  String get writeReviewFairPrice => '良心的な価格';

  @override
  String get writeReviewReviewHasBeenPosted => 'レビューを投稿しました';

  @override
  String get writeReviewShareExperienceThisSeller => 'この出品者との取引の感想を共有しましょう...';

  @override
  String get writeReviewUpdateReview => 'レビューを更新';

  @override
  String get writeReviewSubmitReview => 'レビューを投稿';

  @override
  String get interestsSurveyWhatAreInterests => '興味のあるジャンルは？';

  @override
  String get interestsSurveyDiscoverProducts => 'ぴったりの商品を見つけよう';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return '保存して次へ ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => '今はスキップ';

  @override
  String get priceLabel => '価格';

  @override
  String get conditionLabel => '商品の状態';

  @override
  String get conditionNew => '新品・未使用';

  @override
  String get conditionLikeNew => '未使用に近い';

  @override
  String get conditionUsed => '中古';

  @override
  String get fulfillmentMeetInPerson => '手渡し';

  @override
  String get fulfillmentDelivery => '配送';

  @override
  String get listingStatusSold => '売り切れ';

  @override
  String get listingStatusReserved => '取り置き中';

  @override
  String get safetyTipsTitle => '安全取引のヒント';
}
