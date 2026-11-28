// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get chatPlaceholder => 'Escribe al vendedor...';

  @override
  String get chatTypeMessageHint => 'Escribe un mensaje...';

  @override
  String get chatRecordingPlaceholder => 'Grabando...';

  @override
  String get chatAddAttachmentTooltip => 'Añadir archivo adjunto';

  @override
  String get chatMessageInputLabel => 'Campo de mensaje';

  @override
  String get chatSendMessageTooltip => 'Enviar mensaje';

  @override
  String chatStagedAttachmentLabel(Object name) {
    return 'Adjunto preparado: $name';
  }

  @override
  String chatRemoveAttachmentLabel(Object name) {
    return 'Quitar adjunto $name';
  }

  @override
  String get chatDismissMessageMenu => 'Cerrar menú del mensaje';

  @override
  String get chatJumpToLatest => 'Ir al último';

  @override
  String chatNewMessagesJumpToLatest(Object count, Object messageWord) {
    return '$count $messageWord nuevos. Ir al último';
  }

  @override
  String get chatMessageSingular => 'mensaje';

  @override
  String get chatMessagePlural => 'mensajes';

  @override
  String get chatCallAndOptionsTooltip => 'Llamada y opciones del chat';

  @override
  String get chatSendFailedRetrySemantic =>
      ', Error al enviar, toca dos veces para reintentar';

  @override
  String get chatSendingSemantic => ', Enviando';

  @override
  String get chatEditedLabel => 'Editado';

  @override
  String get chatRetrySendingTooltip => 'Reintentar envío del mensaje';

  @override
  String get chatTypingIndicatorLabel => 'Escribiendo...';

  @override
  String get chatPhotoPreviewLabel => '📷 Foto';

  @override
  String get chatVoicePreviewLabel => '🎤 Nota de voz';

  @override
  String get voiceMicMutedIdleSemantic =>
      'Micrófono silenciado. No se detecta audio. Mantén pulsado el micrófono para grabar una nota de voz';

  @override
  String get voiceHoldToRecordSemantic =>
      'Mantén pulsado para grabar una nota de voz. Desliza a la izquierda para cancelar o hacia arriba para bloquear en manos libres';

  @override
  String get voiceMicMutedSuffixSemantic =>
      '. Aviso: micrófono silenciado, no se detecta audio';

  @override
  String voiceReleaseToCancelSemantic(Object mutedSuffix) {
    return 'Suelta para cancelar la grabación de voz$mutedSuffix';
  }

  @override
  String voiceLockedRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Grabación bloqueada en manos libres, $timeStr$mutedSuffix. Toca PARAR para finalizar';
  }

  @override
  String voiceActiveRecordingSemantic(Object timeStr, Object mutedSuffix) {
    return 'Grabando nota de voz, $timeStr$mutedSuffix. Desliza a la izquierda para cancelar o hacia arriba para bloquear';
  }

  @override
  String get voiceWaveformMutedSemantic =>
      'Onda de audio plana, micrófono silenciado';

  @override
  String get voiceWaveformPreviewSemantic =>
      'Onda interactiva de vista previa de audio';

  @override
  String get voiceWaveformLiveSemantic => 'Onda de audio en directo';

  @override
  String get voiceMicMutedWarningSemantic =>
      'Aviso de micrófono silenciado. No se detecta audio.';

  @override
  String get voiceMicMutedBadge => 'Micrófono silenciado';

  @override
  String get voiceCancelRecordingTooltip => 'Cancelar grabación de voz';

  @override
  String get voicePauseRecordingTooltip =>
      'Pausar grabación o vista previa de voz';

  @override
  String get voicePlayPreviewTooltip => 'Reproducir vista previa de voz';

  @override
  String get voiceSendVoiceMessageTooltip => 'Enviar nota de voz';

  @override
  String get voiceReleaseToCancelLabel => 'Suelta para cancelar';

  @override
  String get voiceSlideToCancelLabel => 'Desliza para cancelar';

  @override
  String get voiceHoldMicPrompt =>
      'Mantén pulsado el micrófono para grabar una nota de voz';

  @override
  String get voiceRecordButtonSemantic => 'Grabar nota de voz';

  @override
  String get voiceRecordGestureHint =>
      'Toca o mantén pulsado para grabar. Desliza hacia dentro para cancelar o hacia arriba para bloquear';

  @override
  String get voiceWaveformScrubberSemantic =>
      'Control de progreso de la nota de voz';

  @override
  String get voiceChatTitle => 'Chat de voz';

  @override
  String get voiceMicPermissionRequired =>
      'Se necesita permiso del micrófono para grabar audio.';

  @override
  String get voiceCouldNotStartRecording =>
      'No se pudo iniciar la grabación en este dispositivo.';

  @override
  String get voiceTapMicEmptyPrompt =>
      'Toca el micrófono de abajo para grabar una nota de voz';

  @override
  String get voiceTapMicInputHint =>
      'Toca el micro para grabar una nota de voz...';

  @override
  String get voiceToggleWaveformTooltip =>
      'Cambiar vista de onda ajustada / desplazable';

  @override
  String get voiceToggleThemeTooltip => 'Cambiar tema GTA 6';

  @override
  String get otpVerifyCodeTitle => 'Verifica tu código';

  @override
  String otpEnterSixDigitCode(Object destination) {
    return 'Introduce el código de 6 dígitos enviado a $destination';
  }

  @override
  String get otpCodeVerifiedLabel => 'Código verificado';

  @override
  String get otpIncorrectCodeError => 'Código incorrecto, inténtalo de nuevo';

  @override
  String otpResendCodeCountdown(Object seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get otpResendCodeButton => 'Reenviar código';

  @override
  String get welcomeContinueAsGuestLabel => 'Continuar como invitado';

  @override
  String get authEmailPlaceholder => 'example@gmail.com';

  @override
  String get authPasswordPlaceholder => 'Contraseña';

  @override
  String get authFullNamePlaceholder => 'Nombre';

  @override
  String get authUsernameHandlePlaceholder => '@username';

  @override
  String get authPlainUsernamePlaceholder => 'usuario';

  @override
  String get moroccoPhonePlaceholder => '+212 6XX XXX XXX';

  @override
  String likeButtonSemantic(Object count) {
    return 'Me gusta, $count me gusta';
  }

  @override
  String unlikeButtonSemantic(Object count) {
    return 'Quitar me gusta, $count me gusta';
  }

  @override
  String get likeSyncFailedSemantic =>
      'No se pudo guardar tu me gusta. Toca para reintentar';

  @override
  String get pullToRefreshRefreshing => 'Actualizando lista';

  @override
  String get pullToRefreshRelease => 'Suelta para actualizar';

  @override
  String get pullToRefreshPullDown => 'Desliza hacia abajo para actualizar';

  @override
  String get badgeOnlineSemantic => 'En línea';

  @override
  String get badgeUnreadNotificationSemantic => 'Notificación sin leer';

  @override
  String get badgeUnreadMaxSemantic => '99+ notificaciones sin leer';

  @override
  String badgeUnreadCountSemantic(Object count, Object notificationWord) {
    return '$count $notificationWord sin leer';
  }

  @override
  String get notificationSingular => 'notificación';

  @override
  String get notificationPlural => 'notificaciones';

  @override
  String emojiReactWithSemantic(Object emoji) {
    return 'Reaccionar con $emoji';
  }

  @override
  String get emojiFewerTooltip => 'Menos emojis';

  @override
  String get emojiMoreTooltip => 'Más emojis';

  @override
  String get listingFavoriteTooltip => 'Guardar anuncio en favoritos';

  @override
  String get accommodationFavoriteTooltip => 'Guardar alojamiento en favoritos';

  @override
  String listingBedroomsCount(Object bedrooms) {
    return '$bedrooms dormitorios';
  }

  @override
  String get listingTaxesIncluded => 'impuestos incl.';

  @override
  String accommodationTotalForNights(Object total, Object nights) {
    return '$total en total · $nights noches';
  }

  @override
  String get boostActionLabel => 'Destacar';

  @override
  String get liveBadgeLabel => 'EN VIVO';

  @override
  String get meetingEncryptionKeyHint => 'Clave secreta AES-GCM de 256 bits';

  @override
  String get meetingDefaultTitle => 'Reunión Apolo';

  @override
  String get meetingDefaultParticipantName => 'Participante SFU';

  @override
  String get bugReportSafetyHeader => 'Seguridad de Apolo.ma';

  @override
  String get bugReportDescMinLengthError =>
      'La descripción debe tener al menos 5 caracteres.';

  @override
  String get bugReportNetworkFailedError => 'Error en la solicitud de red.';

  @override
  String get bugReportTimeoutError =>
      'Se agotó el tiempo de espera. Comprueba tu conexión y reintenta.';

  @override
  String get bugReportServerUnreachableError =>
      'No podemos conectar con los servidores de Apolo.ma ahora mismo.';

  @override
  String get meetingSignInRequiredError =>
      'Inicia sesión para unirte a la reunión.';

  @override
  String get meetingPermissionDeniedError =>
      'No tienes permiso para acceder a esta reunión.';

  @override
  String get meetingAlreadyEndedError => 'Esta reunión ya ha finalizado.';

  @override
  String get meetingRoomLockedError => 'El anfitrión ha bloqueado esta sala.';

  @override
  String get meetingMaxCapacityError =>
      'Esta reunión ha alcanzado el límite máximo de participantes.';

  @override
  String get meetingServiceUnreachableError =>
      'No se pudo conectar con el servicio de reuniones. Revisa tu conexión.';

  @override
  String get accountOnboardingFormFinishSettingUpAccount =>
      'Termina de configurar tu cuenta';

  @override
  String get accountOnboardingFormChooseCityInterestsYouCan =>
      'Elige tu ciudad e intereses. Puedes cambiar gratis a una cuenta Business cuando quieras en Ajustes.';

  @override
  String get accountOnboardingFormCity => 'Ciudad';

  @override
  String get accountOnboardingFormChooseAtLeastOneInterest =>
      'Elige al menos un interés';

  @override
  String get accountOnboardingFormSaveContinue => 'Guardar y continuar';

  @override
  String get accountOnboardingFormReloadOptions => 'Recargar opciones';

  @override
  String get navHome => 'Inicio';

  @override
  String get navExplore => 'Explorar';

  @override
  String get sellItemButton => 'Vender';

  @override
  String get navStores => 'Tiendas';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get featuredAdsTitle => 'Anuncios VIP';

  @override
  String get latestAdsTitle => 'Últimos anuncios';

  @override
  String get allCitiesFilter => 'Todas las ciudades';

  @override
  String get allCategoriesFilter => 'Todas las categorías';

  @override
  String get loginButton => 'Entrar';

  @override
  String get createAccountButton => 'Crear cuenta';

  @override
  String get logoutButton => 'Salir';

  @override
  String get callSellerButton => 'Llamar';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get chatInAppButton => 'Chat';

  @override
  String get boostAdButton => 'Destacar anuncio';

  @override
  String get deleteAccountButton => 'Eliminar cuenta';

  @override
  String get reportAdButton => 'Denunciar anuncio';

  @override
  String get blockUserButton => 'Bloquear usuario';

  @override
  String get searchHint => 'Busca un coche, piso, móvil...';

  @override
  String get noAdsFoundMessage =>
      'No hemos encontrado anuncios para tu búsqueda';

  @override
  String get appStateDark => 'Oscuro';

  @override
  String get appStateSystem => 'Sistema';

  @override
  String get appStateLight => 'Claro';

  @override
  String get appStateApoloMember => 'Miembro de Apolo';

  @override
  String get appStateJustNow => 'Ahora mismo';

  @override
  String get appStateKm => 'km';

  @override
  String get bugReportReportTechnicalProblem =>
      'Informar de un problema técnico';

  @override
  String get bugReportIfFeatureProductIsnT =>
      'Si alguna función o apartado falla, cuéntanoslo para ayudarnos a mejorar Apolo.ma.';

  @override
  String get bugReportReportProblem => 'Informar de un problema';

  @override
  String get bugReportReportsAboutAbuseSpamShouldn =>
      'Las denuncias por abuso o spam no deben enviarse por aquí.';

  @override
  String get bugReportLearnHowReportAbuseSpam =>
      'Descubre cómo denunciar abusos, spam, fraudes o infracciones de seguridad en Apolo.ma.';

  @override
  String get bugReportShakePhoneReportProblem =>
      'Agita el móvil para informar de un problema';

  @override
  String get bugReportEnabledMobileSensorsDesktopBrowser =>
      'Activado para sensores móviles (el navegador de escritorio no tiene acelerómetro)';

  @override
  String get bugReportToggleEnable => 'Actívalo para habilitar';

  @override
  String get bugReportToggleOffDisable => 'Desactívalo para inhabilitar';

  @override
  String get bugReportReportTechnicalProblem2 => 'Informar de fallo técnico';

  @override
  String get bugReportLearnMoreAboutReportingAbuse =>
      'Más información sobre cómo denunciar abusos o spam';

  @override
  String get bugReportWouldYouLikeIncludeAdditional =>
      '¿Quieres incluir registros y diagnósticos adicionales?';

  @override
  String get bugReportAlwaysCollectedBasicContext =>
      'Contexto básico incluido siempre:';

  @override
  String get bugReportAuthenticatedUserIdIfSigned =>
      'Tu ID de usuario autenticado (si has iniciado sesión), versión/compilación de la app, plataforma/SO, pantalla actual y configuración regional/RTL.';

  @override
  String get bugReportOptionalDiagnosticsOnlyAttachedIf =>
      'Diagnósticos opcionales (solo se adjuntan si aceptas):';

  @override
  String get bugReportRecentMemoryLogBufferNavigation =>
      'Registros recientes en memoria, historial de navegación y errores de API anonimizados, además de datos del dispositivo y pantalla para reproducir el fallo.';

  @override
  String get bugReportIncludeContinue => 'Incluir y continuar';

  @override
  String get bugReportDonTIncludeContinue => 'No incluir y continuar';

  @override
  String get sendButton => 'Enviar';

  @override
  String get bugReportBrieflyExplainWhatHappenedWhat =>
      'Explica brevemente qué ha pasado o qué no funciona.';

  @override
  String get bugReportScreenshot => 'Captura de pantalla';

  @override
  String get bugReportUpload => 'Subir';

  @override
  String get bugReportRemoveScreenshot => 'Quitar captura';

  @override
  String get bugReportPreviewScreenshot => 'Ver captura';

  @override
  String get bugReportAutoCaptureWasnTAvailable =>
      'La captura automática no estaba disponible en esta vista; puedes usar Subir.';

  @override
  String get bugReportPleaseDescribeWhatHappenedBefore =>
      'Describe qué ha pasado antes de enviarlo.';

  @override
  String get bugReportPleaseWriteAtLeast5 =>
      'Escribe al menos 5 caracteres para describir el problema.';

  @override
  String get bugReportImageExceeds5MbMaximum =>
      'La imagen supera el tamaño máximo de 5 MB.';

  @override
  String get bugReportUnsupportedImageFormatPleaseChoose =>
      'Formato de imagen no compatible. Elige JPEG, PNG o WebP.';

  @override
  String get bugReportCouldNotReadSelectedImage =>
      'No se pudo leer la imagen seleccionada.';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get closeButton => 'Cerrar';

  @override
  String bugReportThanksTechnicalReportHasBeen(Object reportId) {
    return '¡Gracias! Hemos recibido tu informe técnico (#$reportId)';
  }

  @override
  String get bugReportThanksTechnicalReportHasBeen2 =>
      '¡Gracias! Hemos recibido tu informe técnico.';

  @override
  String get bugReportCouldNotSendReportRight =>
      'No se pudo enviar el informe ahora mismo. Revisa tu conexión y reintenta.';

  @override
  String bugReportTooManyReportsSentRecently(Object seconds) {
    return 'Has enviado demasiados informes recientemente. Reinténtalo en $seconds segundos.';
  }

  @override
  String get bugReportTooManyReportsSentRecently2 =>
      'Has enviado demasiados informes recientemente. Espera un momento y reintenta.';

  @override
  String get bugReportReportingAbuseSpamSafetyIssues =>
      'Denunciar abusos, spam y problemas de seguridad';

  @override
  String get bugReportThisFormIsStrictlyTechnical =>
      'Este formulario es solo para fallos técnicos. Para denunciar anuncios sospechosos, acoso, fraude o infracciones en Apolo.ma, toca Denunciar en el anuncio o chat, o abre nuestro formulario de seguridad abajo.';

  @override
  String get bugReportOpenSafetyAbuseReport =>
      'Abrir denuncia de seguridad y abuso';

  @override
  String get bugReportFoundBugBrokenScreenSend =>
      '¿Has visto un fallo o una pantalla rota? Envía un informe técnico con una captura opcional.';

  @override
  String get meetingLobby => 'Sala de espera';

  @override
  String get meetingNewGroupMeeting => 'Nueva reunión grupal';

  @override
  String get meetingJoinRoomCode => 'Unirse con código de sala';

  @override
  String get meetingTitle => 'Título de la reunión';

  @override
  String get meetingEGLivePropertyWalkthrough =>
      'p. ej. Visita en directo al piso';

  @override
  String get meetingRoomCodeApoXxxxXxxx => 'Código de sala (apo-xxxx-xxxx)';

  @override
  String get meetingJoinMeeting => 'Unirse a la reunión';

  @override
  String get meetingStartMeeting => 'Iniciar reunión';

  @override
  String get meetingEndEndEncryptionE2ee =>
      'Cifrado de extremo a extremo (E2EE)';

  @override
  String get meetingSfuForwardsEncryptedPacketsWithout =>
      'SFU reenvía paquetes cifrados sin ver nunca tu audio ni vídeo';

  @override
  String get meetingSharedRoomEncryptionKey =>
      'Clave de cifrado compartida de la sala';

  @override
  String get meetingAdaptiveSfuSvc25Participants =>
      'SFU + SVC adaptable (25+ participantes)';

  @override
  String get meetingMicOn => 'Micro activado';

  @override
  String get meetingMuted => 'Silenciado';

  @override
  String get meetingCameraOn => 'Cámara activada';

  @override
  String get meetingCameraOff => 'Cámara apagada';

  @override
  String get meetingShareScreen => 'Compartir pantalla';

  @override
  String get meetingStopSharing => 'Dejar de compartir';

  @override
  String get meetingSpeaker => 'Altavoz';

  @override
  String get meetingFlipCamera => 'Cambiar cámara';

  @override
  String get meetingParticipants => 'Participantes';

  @override
  String get meetingLeave => 'Salir';

  @override
  String get meetingEndAll => 'Finalizar para todos';

  @override
  String get meetingUnstableNetworkAutomaticallyReconnectingVia =>
      'Red inestable... Reconectando automáticamente por UDP/TURN';

  @override
  String get meetingLowBandwidthVideoLayersStepped =>
      'Ancho de banda bajo: calidad de vídeo ajustada (SVC) para proteger el audio y la batería';

  @override
  String get meetingAudioOnly => 'Solo audio';

  @override
  String get meetingResumeVideo => 'Reanudar vídeo';

  @override
  String get meetingDataBatterySaverAudioOnly =>
      'Ahorro de datos y batería (solo audio) activo';

  @override
  String get meetingYou => 'Tú';

  @override
  String get meetingHost => 'Anfitrión';

  @override
  String get meetingCoHost => 'Coanfitrión';

  @override
  String get meetingLockRoom => 'Bloquear sala';

  @override
  String get meetingUnlockRoom => 'Desbloquear sala';

  @override
  String get meetingMuteMic => 'Silenciar micro';

  @override
  String get meetingRemove => 'Expulsar';

  @override
  String get meetingCopyInviteLink => 'Copiar enlace de invitación';

  @override
  String get meetingInviteCopied => 'Invitación copiada';

  @override
  String get meetingConnectingSecureSfuMediaRouter =>
      'Conectando al router seguro SFU...';

  @override
  String meetingPageCurrentTotal(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get accountSecurityEnterValidEmailAddress =>
      'Introduce un correo electrónico válido.';

  @override
  String get accountSecurityEnterValidPhoneNumber =>
      'Introduce un número de teléfono válido.';

  @override
  String get accountSecurityContactDetailsUpdatedSuccessfully =>
      'Datos de contacto actualizados correctamente.';

  @override
  String get accountSecurityPasswordMustBeAtLeast =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get accountSecurityPasswordsDoNotMatch =>
      'Las contraseñas no coinciden.';

  @override
  String get accountSecurityPasswordUpdatedSuccessfully =>
      'Contraseña actualizada correctamente.';

  @override
  String get accountSecurityAccountSecurity => 'Seguridad de la cuenta';

  @override
  String get accountSecurityStayControlLogin =>
      'Mantén el control de tu acceso';

  @override
  String get accountSecurityUpdatePasswordEmailPhoneDirectly =>
      'Actualiza tu contraseña, correo o teléfono directamente desde la app.';

  @override
  String get accountSecurityContactDetails => 'Datos de contacto';

  @override
  String get accountSecurityEmailAddress => 'Correo electrónico';

  @override
  String get accountSecurityPhoneNumber => 'Número de teléfono';

  @override
  String get accountSecuritySaveContactDetails => 'Guardar datos de contacto';

  @override
  String get accountSecurityChangePassword => 'Cambiar contraseña';

  @override
  String get accountSecurityCurrentPassword => 'Contraseña actual';

  @override
  String get accountSecurityNewPassword => 'Nueva contraseña';

  @override
  String get accountSecurityConfirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get accountSecurityUpdatePassword => 'Actualizar contraseña';

  @override
  String get accountSecuritySecurityOptions => 'Opciones de seguridad';

  @override
  String get accountSecuritySignUpdateThisInformation =>
      'Inicia sesión para actualizar esta información';

  @override
  String get accountSetupCreateAccount => 'Crear cuenta';

  @override
  String get accountSetupAccountType => 'Tipo de cuenta';

  @override
  String get accountSetupChooseAtLeastOneProfile =>
      'Elige al menos un tipo de perfil para personalizar tu cuenta.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get adDetailHiIsThisStillAvailable => '¡Hola! ¿Sigue disponible?';

  @override
  String get adDetailCouldNotUpdateFavoritesPlease =>
      'No se pudieron actualizar tus favoritos. Inténtalo de nuevo.';

  @override
  String get adDetailPhoneNumberCopied => 'Número de teléfono copiado';

  @override
  String get adDetailCopy => 'Copiar';

  @override
  String get adDetailCouldNotStartConversationPlease =>
      'No se pudo iniciar la conversación. Inténtalo de nuevo.';

  @override
  String get adDetailUserBlocked => 'Usuario bloqueado';

  @override
  String get adDetailReportThisListingAiContent =>
      'Denunciar este anuncio o contenido de IA';

  @override
  String get adDetailQuickReviewByTrustSafety =>
      'Revisión rápida de nuestro equipo de Confianza y Seguridad';

  @override
  String get adDetailHideAllListingsFromThis =>
      'Ocultar todos los anuncios de este vendedor';

  @override
  String get adDetailDetails => 'Detalles';

  @override
  String get adDetailListingUnavailable => 'Anuncio no disponible';

  @override
  String get adDetailThisItemMayHaveBeen =>
      'Puede que el vendedor ya haya vendido o retirado este artículo.';

  @override
  String get adDetailGoBack => 'Volver';

  @override
  String get adDetailCategory => 'Categoría';

  @override
  String get adDetailCondition => 'Estado';

  @override
  String get adDetailNotSpecified => 'No especificado';

  @override
  String get adDetailReference => 'Referencia';

  @override
  String get backButton => 'Volver';

  @override
  String get adDetailFavorite => 'Favorito';

  @override
  String get adDetailMore => 'Más';

  @override
  String get adDetailFree => 'Gratis';

  @override
  String get adDetailOnRequest => 'A consultar';

  @override
  String get negotiableBadge => 'Negociable';

  @override
  String get fixedPriceBadge => 'Precio fijo';

  @override
  String get adDetailGuests => 'Huéspedes';

  @override
  String get adDetailBedrooms => 'Dormitorios';

  @override
  String get adDetailBeds => 'Camas';

  @override
  String get adDetailBaths => 'Baños';

  @override
  String get adDetailGood => 'Buen estado';

  @override
  String get adDetailRef => 'Ref.';

  @override
  String get adDetailViews => 'Visitas';

  @override
  String get adDetailGuestFavourite => 'Favorito entre huéspedes';

  @override
  String get adDetailVideoTour => 'Vídeo tour';

  @override
  String adDetailJustListedMMAgo(Object m) {
    return 'Recién publicado · hace $m min';
  }

  @override
  String adDetailJustListedHHoursAgo(Object h) {
    return 'Recién publicado · hace $h h';
  }

  @override
  String adDetailDDaysAgo(Object d) {
    return 'Hace $d días';
  }

  @override
  String get adDetailJustListed => 'Recién publicado';

  @override
  String get adDetailBoostThisListing => 'Destacar este anuncio ⚡';

  @override
  String get adDetailMessageSeller => 'Escribir al vendedor';

  @override
  String get adDetailFastReply => 'Respuesta rápida';

  @override
  String get adDetailWriteMessage => 'Escribe un mensaje...';

  @override
  String get adDetailAlertsEnabledSimilarListings =>
      'Alertas activadas para anuncios similares';

  @override
  String get adDetailAlertsPaused => 'Alertas pausadas';

  @override
  String get adDetailAlerts => 'Alertas';

  @override
  String get adDetailMessage => 'Mensaje';

  @override
  String get shareButton => 'Compartir';

  @override
  String get saveButton => 'Guardar';

  @override
  String get adDetailNoDescriptionProvidedMessageSeller =>
      'Sin descripción. Escribe al vendedor para más detalles.';

  @override
  String get adDetailDescription => 'Descripción';

  @override
  String get adDetailSeeLess => 'Ver menos';

  @override
  String get adDetailSeeMore => 'Ver más';

  @override
  String get adDetailCallSeller => 'Llamar al vendedor';

  @override
  String adDetailApoloStoreCityname(Object cityName) {
    return 'Tienda Apolo · $cityName';
  }

  @override
  String adDetailApoloSellerCityname(Object cityName) {
    return 'Vendedor en Apolo · $cityName';
  }

  @override
  String get adDetailBusinessStore => 'Tienda Business';

  @override
  String get adDetailSeller => 'Vendedor';

  @override
  String get adDetailSeeReviews => 'Ver valoraciones';

  @override
  String get followingButton => 'Siguiendo';

  @override
  String get followButton => 'Seguir';

  @override
  String get adDetailYourRating => 'Tu valoración';

  @override
  String get adDetailRateThisSeller => 'Valorar a este vendedor';

  @override
  String get adDetailEditReview => 'Editar reseña';

  @override
  String get adDetailWriteReview => 'Escribir reseña';

  @override
  String get adDetailLocation => 'Ubicación';

  @override
  String adDetailZoneDistkmKm(Object distKm) {
    return 'En tu zona · $distKm km';
  }

  @override
  String adDetailDistkmKmAway(Object distKm) {
    return 'A $distKm km';
  }

  @override
  String get adDetailLocationIsApproximate => 'La ubicación es aproximada';

  @override
  String get adDetailFullMap => 'Mapa completo';

  @override
  String get adDetailRelatedSearches => 'Búsquedas relacionadas';

  @override
  String get adDetailIfYouDonTLike => 'Si no te interesa, puedes ';

  @override
  String get adDetailHideThisListing => 'ocultar este anuncio';

  @override
  String get adDetailWeLlShowYouFewer =>
      ' y te mostraremos menos anuncios como este.';

  @override
  String get adDetailListingHiddenFromFeed => 'Anuncio ocultado de tu feed';

  @override
  String get adDetailListingRestored => 'Anuncio restaurado';

  @override
  String get adDetailHidden => 'Oculto';

  @override
  String get adDetailHideListing => 'Ocultar anuncio';

  @override
  String get adDetailReportSafety => 'Denunciar y seguridad';

  @override
  String get adDetailSimilarListings => 'Anuncios similares';

  @override
  String get adDetailAllReviews => 'Todas las valoraciones';

  @override
  String get adDetailSellerRating => 'Valoración del vendedor';

  @override
  String get adDetailEditReview2 => 'Editar tu reseña';

  @override
  String get adDetailWriteReview2 => 'Escribir una reseña';

  @override
  String adDetailSellerReviewsTotalcount(Object totalCount) {
    return 'Valoraciones del vendedor ($totalCount)';
  }

  @override
  String get adDetailShowAll => 'Mostrar todas';

  @override
  String get adDetail5Stars => '5 estrellas';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get adDetailHighest => 'Más altas';

  @override
  String get adDetailSort => 'Ordenar';

  @override
  String adDetailNoWrittenReviewsSellernameYet(Object sellerName) {
    return '$sellerName aún no tiene reseñas escritas';
  }

  @override
  String get adDetailHelpful => 'Útil';

  @override
  String get addFriendsJoinMeApoloMaMorocco =>
      'Únete a mí en Apolo.ma — el marketplace de Marruecos: https://apolo.ma';

  @override
  String get addFriendsAddFriends => 'Añade a tus amigos';

  @override
  String get addFriendsInvited => 'Invitado';

  @override
  String get addFriendsInvite => 'Invitar';

  @override
  String get addFriendsContacts => 'Contactos';

  @override
  String get authUnableOpenGoogleSignRight =>
      'No se puede abrir el acceso con Google ahora mismo.';

  @override
  String get authUnableStartGoogleSign =>
      'No se pudo iniciar el acceso con Google.';

  @override
  String get authNoEmailAddressIsLinked =>
      'No hay ningún correo vinculado a esta cuenta para recibir el código.';

  @override
  String authVerificationCodeWasSentMasked(Object masked) {
    return 'Hemos enviado un código de verificación a $masked.';
  }

  @override
  String get authPleaseEnterValidEmailAddress =>
      'Introduce un correo electrónico válido';

  @override
  String get authPasswordMustBeAtLeast =>
      'Tu contraseña debe tener al menos 8 caracteres';

  @override
  String get authPleaseEnterNameAtLeast =>
      'Introduce tu nombre (mínimo 2 caracteres)';

  @override
  String get authUsernameMustBeAtLeast =>
      'El nombre de usuario debe tener al menos 3 letras o números';

  @override
  String get authPleaseEnterValidMoroccanPhone =>
      'Introduce un teléfono marroquí válido (p. ej. 650-123456)';

  @override
  String get authEnter6DigitVerificationCode =>
      'Introduce el código de verificación de 6 dígitos.';

  @override
  String authNewVerificationCodeWasSent(Object masked) {
    return 'Hemos enviado un nuevo código de verificación a $masked.';
  }

  @override
  String get authNewVerificationCodeWasSent2 =>
      'Hemos enviado un nuevo código de verificación a tu correo.';

  @override
  String authBasevalueTriedAtHhMm(Object baseValue, Object hh, Object mm) {
    return '$baseValue (Intentado a las $hh:$mm)';
  }

  @override
  String get signUpButton => 'Regístrate';

  @override
  String get authEnterEmail => 'Introduce tu correo';

  @override
  String get authEnterPassword => 'Introduce tu contraseña';

  @override
  String get authForgotPassword => '¿Has olvidado tu contraseña?';

  @override
  String get authWhatSEmail => '¿Cuál es tu correo?';

  @override
  String get authChoosePassword => 'Elige una contraseña';

  @override
  String get authWhatSFirstName => '¿Cómo te llamas?';

  @override
  String get authPickUsername => 'Elige un nombre de usuario';

  @override
  String get authOthersCanFindYouUsername =>
      '¡Otros usuarios podrán encontrarte con tu nombre de usuario!';

  @override
  String get authWhatSPhoneNumber => '¿Cuál es tu número de teléfono?';

  @override
  String get authEnterValidMoroccanPhoneNumber =>
      'Introduce un teléfono marroquí válido para proteger tu cuenta';

  @override
  String authWeSent6DigitVerification(Object maskedEmail) {
    return 'Hemos enviado un código de verificación de 6 dígitos a $maskedEmail';
  }

  @override
  String get authWeSent6DigitVerification2 =>
      'Hemos enviado un código de verificación de 6 dígitos a tu correo';

  @override
  String get authEnterVerificationCode => 'Introduce el código de verificación';

  @override
  String get authSending => 'Enviando...';

  @override
  String authResendCodeRemainingS(Object remaining) {
    return 'Reenviar código (${remaining}s)';
  }

  @override
  String get businessSwitchWelcomeStoreApoloHowCan =>
      '¡Bienvenido a nuestra tienda en Apolo! ¿En qué podemos ayudarte hoy?';

  @override
  String get businessSwitchPleaseEnterStoreNameAt =>
      'Introduce un nombre de tienda (mínimo 2 caracteres).';

  @override
  String get businessSwitchPleaseEnterStoreName =>
      'Introduce el nombre de tu tienda.';

  @override
  String get businessSwitchBusinessProfileUpdated =>
      '¡Perfil Business actualizado!';

  @override
  String get businessSwitchVerifiedBusinessStoreIsNow =>
      '¡Tu tienda Business verificada ya está activa!';

  @override
  String get businessSwitchCouldNotSaveBusinessProfile =>
      'No se pudo guardar el perfil Business. Inténtalo de nuevo.';

  @override
  String get businessSwitchBusinessSettings => 'Ajustes de Business';

  @override
  String get businessSwitchSwitchBusiness => 'Cambiar a Business';

  @override
  String get businessSwitchPreviousStoreDetailsAreReady =>
      '¡Los datos anteriores de tu tienda están listos para reactivarse!';

  @override
  String get savingLabel => 'Guardando...';

  @override
  String get businessSwitchSaveChanges => 'Guardar cambios';

  @override
  String get businessSwitchActivateFreeBusiness => 'Activar Business gratis';

  @override
  String get businessSwitchWhatBestDescribesBusiness =>
      '¿Qué describe mejor tu negocio?';

  @override
  String get businessSwitchThisCategoryBadgeAppearsUnder =>
      'Esta insignia de categoría aparece bajo tu nombre en tu perfil y tienda.';

  @override
  String get businessSwitchStoreIdentityHoursLocation =>
      'Identidad, horario y ubicación de la tienda';

  @override
  String get businessSwitchStoreAppearsStoresDirectoryOnce =>
      'Tu tienda aparecerá en el directorio de Tiendas en cuanto tengas al menos 1 anuncio activo.';

  @override
  String get businessSwitchStoreName => 'Nombre de la tienda *';

  @override
  String get businessSwitchEGAutoCasa => 'p. ej. Auto Casa';

  @override
  String get businessSwitchBioDescription => 'Biografía / Descripción';

  @override
  String get businessSwitchTellCustomersAboutProductsService =>
      'Cuéntales a tus clientes qué productos y servicios ofreces...';

  @override
  String get businessSwitchCityAddress => 'Ciudad y dirección';

  @override
  String get businessSwitchEGMaarifCasablanca => 'p. ej. Maarif, Casablanca';

  @override
  String get businessSwitchGoogleMapsLinkOptional =>
      'Enlace de Google Maps (opcional)';

  @override
  String get businessSwitchWorkingHours => 'Horario comercial';

  @override
  String get businessSwitchContactDirectOrderTools =>
      'Contacto y pedidos directos';

  @override
  String get businessSwitchEnable1TapOrdersAutomatic =>
      'Activa pedidos en 1 toque y saludos automáticos en el chat.';

  @override
  String get businessSwitchBusinessPhone => 'Teléfono comercial';

  @override
  String get businessSwitchEnableDirectOrderButtonStore =>
      'Activar botón de \"Pedido directo\" en la tienda';

  @override
  String get businessSwitchReceiveInstantOrdersCustomerDetails =>
      'Recibe pedidos al instante con los datos del cliente.';

  @override
  String get businessSwitchAutoGreetingMessageChat =>
      'Mensaje de bienvenida automático en el chat';

  @override
  String get businessSwitchWelcomeStoreHowCanWe =>
      '¡Bienvenido a nuestra tienda! ¿En qué te ayudamos?';

  @override
  String get callIncomingVideoCall => 'Videollamada entrante...';

  @override
  String get callIncomingVoiceCall => 'Llamada de voz entrante...';

  @override
  String get callRinging => 'Llamando...';

  @override
  String get callAllowMicCameraAccess => 'Permitir acceso a micro y cámara';

  @override
  String get callConnecting => 'Conectando...';

  @override
  String get callCalls => 'Llamadas';

  @override
  String get callCallsAreUnavailableThisDevice =>
      'Las llamadas no están disponibles en este dispositivo';

  @override
  String get callBackChat => 'Volver al chat';

  @override
  String get callVideoCall => 'Videollamada';

  @override
  String get callVoiceCall => 'Llamada de voz';

  @override
  String get callDecline => 'Rechazar';

  @override
  String get callAccept => 'Aceptar';

  @override
  String get callMic => 'Micro';

  @override
  String get callCamera => 'Cámara';

  @override
  String get callEnd => 'Colgar';

  @override
  String chatListLastMessageLasttime(Object lastTime) {
    return 'Último mensaje $lastTime';
  }

  @override
  String get chatListUnpinChat => 'Desfijar chat';

  @override
  String get chatListPinChat => 'Fijar chat';

  @override
  String get chatListChatUnpinned => 'Chat desfijado';

  @override
  String get chatListChatPinnedTop => 'Chat fijado arriba';

  @override
  String get chatListMarkAsRead => 'Marcar como leído';

  @override
  String get chatListUnmuteNotifications => 'Activar notificaciones';

  @override
  String get chatListMuteNotifications => 'Silenciar notificaciones';

  @override
  String get chatListNotificationsUnmuted => 'Notificaciones activadas';

  @override
  String get chatListChatMuted => 'Chat silenciado';

  @override
  String get chatListArchiveChat => 'Archivar chat';

  @override
  String get chatListChatArchived => 'Chat archivado';

  @override
  String get chatListReportChat => 'Denunciar chat';

  @override
  String chatListBlockPeername(Object peerName) {
    return 'Bloquear a $peerName';
  }

  @override
  String chatListBlockedPeername(Object peerName) {
    return 'Has bloqueado a $peerName';
  }

  @override
  String get chatListDeleteChat => 'Eliminar chat';

  @override
  String get chatListChatDeleted => 'Chat eliminado';

  @override
  String get chatListSelectConversationStartMessaging =>
      'Selecciona una conversación para empezar a chatear';

  @override
  String get chatListChats => 'Chats';

  @override
  String get chatListMarkAllRead => 'Marcar todo leído';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get chatListAll => 'Todos';

  @override
  String get chatListUnread => 'No leídos';

  @override
  String get chatListPinned => 'Fijados';

  @override
  String get chatListSignViewChats => 'Inicia sesión para ver tus chats';

  @override
  String get chatListMessageBuyersSellersDirectlySecurely =>
      'Habla con compradores y vendedores de forma directa y segura.';

  @override
  String get signInButton => 'Entrar';

  @override
  String get chatListNoUnreadChats => 'No tienes chats sin leer';

  @override
  String get chatListNoPinnedChats => 'No tienes chats fijados';

  @override
  String get chatListNoChatsYet => 'Aún no tienes chats';

  @override
  String get chatListBrowseListingsMessageSellersDirectly =>
      'Explora anuncios y escribe directamente a los vendedores.';

  @override
  String get chatListExploreListings => 'Explorar anuncios';

  @override
  String get chatListPersonalMessagesAreEndEnd =>
      'Tus mensajes personales están cifrados de extremo a extremo';

  @override
  String get chatRoomFailedLoadMessagesPleaseTry =>
      'Error al cargar los mensajes. Inténtalo de nuevo.';

  @override
  String get chatRoomMessageEdited => 'Mensaje editado';

  @override
  String get chatRoomDeletedEveryone => 'Eliminado para todos';

  @override
  String get chatRoomMessagePinned => 'Mensaje fijado';

  @override
  String get chatRoomMessageUnpinned => 'Mensaje desfijado';

  @override
  String get chatRoomMessageStarred => 'Mensaje destacado ⭐';

  @override
  String get chatRoomStarRemoved => 'Estrella quitada';

  @override
  String get chatRoomReportConversation => 'Denunciar conversación';

  @override
  String get chatRoomUserUnblocked => 'Usuario desbloqueado';

  @override
  String chatRoomUnblockPeername(Object peerName) {
    return 'Desbloquear a $peerName';
  }

  @override
  String get chatRoomReply => 'Responder';

  @override
  String get chatRoomUnpin => 'Desfijar';

  @override
  String get chatRoomPin => 'Fijar';

  @override
  String get chatRoomUnstar => 'Quitar estrella';

  @override
  String get chatRoomStar => 'Destacar';

  @override
  String get chatRoomCopied => 'Copiado';

  @override
  String get editButton => 'Editar';

  @override
  String get reportButton => 'Denunciar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get chatRoomDeleteEveryone => 'Eliminar para todos';

  @override
  String get chatRoomMorocco => 'Marruecos';

  @override
  String chatRoomMyLocationResolvedcity(Object resolvedCity) {
    return '📍 Mi ubicación: $resolvedCity';
  }

  @override
  String chatRoomPriceOfferTitleDhCleaned(Object title, Object cleaned) {
    return '💰 Oferta por \"$title\": DH $cleaned';
  }

  @override
  String chatRoomPriceOfferDhCleaned(Object cleaned) {
    return '💰 Oferta: DH $cleaned';
  }

  @override
  String get chatRoomCouldNotCaptureAudioPlease =>
      'No se pudo grabar el audio. Permite el acceso al micrófono e inténtalo de nuevo.';

  @override
  String get chatRoomVoiceMessageIsTooLong =>
      'La nota de voz es demasiado larga. Graba un mensaje más corto.';

  @override
  String get chatRoomThisMessageWasDeleted => 'Este mensaje fue eliminado';

  @override
  String get chatRoomRead => 'Leído';

  @override
  String get chatRoomDelivered => 'Entregado';

  @override
  String chatRoomLastSeenClock(Object clock) {
    return 'Últ. vez $clock';
  }

  @override
  String get chatRoomOffline => 'Desconectado';

  @override
  String get chatRoomVideoCallUnavailable => 'Videollamada — no disponible';

  @override
  String get chatRoomVoiceCallUnavailable => 'Llamada de voz — no disponible';

  @override
  String get chatRoomSafetyReport => 'Seguridad y denuncia';

  @override
  String get chatRoomYouBlockedThisUser => 'Has bloqueado a este usuario';

  @override
  String get chatRoomUnblock => 'Desbloquear';

  @override
  String get chatRoomEditingMessage => 'Editando mensaje';

  @override
  String get chatRoomSendMessage => 'Enviar un mensaje';

  @override
  String get editProfileMinimum3CharactersRequired => 'Mínimo 3 caracteres';

  @override
  String editProfileCleanIsAvailable(Object clean) {
    return '@$clean está disponible';
  }

  @override
  String get editProfileAlreadyTaken => 'Ya está en uso.';

  @override
  String get editProfileProfilePhoto => 'Foto de perfil';

  @override
  String get editProfileChooseFromLibrary => 'Elegir de la galería';

  @override
  String get editProfileTakePhoto => 'Hacer foto';

  @override
  String get editProfileRemoveCurrentPhoto => 'Eliminar foto actual';

  @override
  String get editProfileChoosePresetAvatar =>
      'O elige un avatar predeterminado';

  @override
  String get editProfileSelectCity => 'Selecciona tu ciudad';

  @override
  String get clearButton => 'Borrar';

  @override
  String get editProfilePhoneWhatsapp => 'Teléfono y WhatsApp';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get editProfileNameIsRequired => 'El nombre es obligatorio.';

  @override
  String get editProfileUsernameMustBeAtLeast =>
      'El nombre de usuario debe tener al menos 3 caracteres.';

  @override
  String get editProfileThisUsernameIsAlreadyTaken =>
      'Este nombre de usuario ya está en uso.';

  @override
  String get editProfileCouldNotSaveChangesPlease =>
      'No se pudieron guardar los cambios. Inténtalo de nuevo.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileEditPicture => 'Cambiar foto';

  @override
  String get editProfileFullName => 'Tu nombre completo';

  @override
  String get editProfileUsername => 'Nombre de usuario';

  @override
  String get editProfileBio => 'Biografía';

  @override
  String get editProfileWriteShortBioAboutYourself =>
      'Escribe una breve presentación sobre ti...';

  @override
  String get editProfileAddCity => 'Añadir ciudad';

  @override
  String get editProfilePhone => 'Teléfono';

  @override
  String get editProfileAddPhoneNumber => 'Añadir número de teléfono';

  @override
  String get editProfileManageStoreDetails => 'Gestionar datos de la tienda';

  @override
  String get editProfileGetVerifiedBusinessStore =>
      'Consigue Verificado y tienda Business';

  @override
  String get editProfilePersonalInformation => 'Información personal';

  @override
  String get editProfileEmailPasswordSettings =>
      'Ajustes de correo y contraseña';

  @override
  String get saveChangesButton => 'Guardar cambios';

  @override
  String forgotPasswordWeSent6DigitVerification(Object masked) {
    return 'Hemos enviado un código de verificación de 6 dígitos a $masked.';
  }

  @override
  String get forgotPasswordPleaseEnter6DigitVerification =>
      'Introduce el código de verificación de 6 dígitos.';

  @override
  String get forgotPasswordPasswordUpdatedSignedSuccessfully =>
      '¡Contraseña actualizada y sesión iniciada!';

  @override
  String get forgotPasswordYouWillReceiveEmailSet =>
      'Recibirás un correo para crear una nueva contraseña';

  @override
  String get forgotPasswordChooseNewPassword => 'Elige una nueva contraseña';

  @override
  String get homeInternetConnectionLost => 'Sin conexión a internet';

  @override
  String get homeCheckNetworkConnectionTryAgain =>
      'Revisa tu conexión de red y vuelve a intentarlo para cargar los anuncios.';

  @override
  String get tryAgainButton => 'Reintentar';

  @override
  String get homeWelcomeApolo => 'Te damos la bienvenida a Apolo';

  @override
  String get homeSearchCarsHomesPhonesAccounts =>
      'Busca coches, casas, móviles o cuentas...';

  @override
  String get homeLatestListings => 'Últimos anuncios';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String homeNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'Aún no hay anuncios a menos de $zoneRadiusKm km de $s';
  }

  @override
  String get homeShowAllMorocco => 'Ver todo Marruecos';

  @override
  String get homeChangeZone => 'Cambiar zona';

  @override
  String get homeBrowseAllListingsMorocco =>
      'Ver todos los anuncios en Marruecos';

  @override
  String get home1MarketplaceMorocco =>
      'El marketplace n.º 1 en Marruecos 🇲🇦';

  @override
  String get homeBuySellSafelyWithoutMiddlemen =>
      'Compra y vende de forma segura sin intermediarios';

  @override
  String get homeCarsPhonesRealEstateDiscover =>
      'Coches, móviles, inmobiliaria. Descubre anuncios cerca de ti.';

  @override
  String get homeExclusiveDeals => 'Ofertas exclusivas';

  @override
  String get homeWhyChooseApolo => '¿Por qué elegir Apolo?';

  @override
  String get home0CommissionFree => '0% comisión y gratis';

  @override
  String get homeBuySellFreeZeroMiddlemen =>
      'Compra y vende gratis, sin intermediarios.';

  @override
  String get homeDirectChatCall => 'Chat y llamada directa';

  @override
  String get homeMessageSellerDirectlyMakeOffer =>
      'Escribe directamente al vendedor y haz tu oferta en un toque.';

  @override
  String get homeVerifiedListings => 'Anuncios verificados';

  @override
  String get homeContinuousReviewKeepAllTransactions =>
      'Revisión continua para que cada trato sea seguro.';

  @override
  String get homeGotSomethingSellPostNow =>
      '¿Tienes algo que vender? Publícalo ya';

  @override
  String get homePublishFree30SecondsGet =>
      'Publica gratis en 30 segundos y recibe mensajes al instante';

  @override
  String get homePost => 'Publicar +';

  @override
  String get homeVerifiedOfficialStores => 'Tiendas oficiales verificadas';

  @override
  String get homeBrowseDealsFromCertifiedStores =>
      'Descubre ofertas de tiendas y agencias certificadas';

  @override
  String get intentOnboardingWhatWillYouUseApolo =>
      '¿Para qué vas a\nusar Apolo?';

  @override
  String get mainShellYouHaveNewApoloNotification =>
      'Tienes una nueva notificación en Apolo';

  @override
  String get mainShellBrowse => 'Explorar';

  @override
  String get notificationsEnableNotifications => 'Activar notificaciones';

  @override
  String get notificationsAreBlocked => 'Las notificaciones están bloqueadas';

  @override
  String get notificationsPleaseEnableNotificationsPhoneBrowser =>
      'Activa las notificaciones en los ajustes de tu móvil o navegador y vuelve a tocar Continuar.';

  @override
  String get notificationsGotIt => 'Entendido';

  @override
  String get notificationsNotificationPreferences =>
      'Preferencias de notificaciones';

  @override
  String get notificationsChooseWhichApoloAlertsYou =>
      'Elige qué alertas de Apolo quieres recibir';

  @override
  String get notificationsMessagesBuyerOffers =>
      'Mensajes y ofertas de compradores';

  @override
  String get notificationsInstantAlertWhenBuyerMessages =>
      'Aviso al instante cuando alguien te escriba o haga una oferta';

  @override
  String get notificationsPriceDropsSavedListings =>
      'Bajadas de precio y favoritos';

  @override
  String get notificationsUpdatesListingsYouBookmarked =>
      'Novedades en los anuncios que has guardado';

  @override
  String get notificationsOfficialStoresUpdates =>
      'Tiendas oficiales y novedades';

  @override
  String get notificationsNewArrivalsFromVerifiedSellers =>
      'Nuevos artículos de los vendedores verificados que sigues';

  @override
  String get notificationsMarkAllAsRead => 'Marcar todo como leído';

  @override
  String get doneButton => 'Listo';

  @override
  String get notificationsPleaseAllowNotificationsContinue =>
      'Permite las notificaciones para continuar';

  @override
  String get notificationsActivatedInstantAlerts =>
      ' activó alertas instantáneas para ';

  @override
  String get notificationsApoloMaBuyerMessagesOffers =>
      'Apolo.ma — Mensajes y ofertas de compradores';

  @override
  String get notificationsJustNow => 'ahora mismo';

  @override
  String get notificationsApoloTeam => 'Equipo Apolo';

  @override
  String get notificationsSharedTipAddClearPhotos =>
      ' compartió un consejo: añade fotos claras a tu anuncio para vender más rápido.';

  @override
  String get notifications2hAgo => 'hace 2 h';

  @override
  String get notificationsApoloOfficialStores => 'Tiendas oficiales de Apolo';

  @override
  String get notificationsUpdated => ' actualizó ';

  @override
  String get notificationsVerifiedCarsRealEstateTech =>
      'Anuncios verificados de motor, inmobiliaria y tecnología';

  @override
  String get notificationsAcrossAllMoroccanCities =>
      ' en todas las ciudades de Marruecos.';

  @override
  String get notificationsThisWeek => 'Esta semana';

  @override
  String get notificationsNotifications => 'Notificaciones';

  @override
  String get notificationsHeyItSApolo => '¡Hola, soy Apolo!';

  @override
  String get notificationsIAmReadyHelpYou =>
      'Estoy listo para echarte una mano. ¿Y tú?';

  @override
  String get notificationsNow => 'ahora';

  @override
  String get notificationsNotification => 'Notificación';

  @override
  String get notificationsActivateNotificationsReceiveMessages =>
      'Activa las notificaciones para enterarte de tus mensajes';

  @override
  String get notificationsUpdates => 'Novedades';

  @override
  String get notificationsNoNotificationsThisCategory =>
      'No hay notificaciones en esta categoría';

  @override
  String get notificationsBuyerMessagesOffersListingUpdates =>
      'Aquí verás los mensajes de compradores, ofertas y novedades de tus anuncios.';

  @override
  String get notificationsNoInternetConnection => 'Sin conexión a internet';

  @override
  String get notificationsCheckWiFiMobileData =>
      'Comprueba tu Wi-Fi o datos móviles para actualizar tus notificaciones.';

  @override
  String get notificationsToday => 'Hoy';

  @override
  String get postAdCouldNotDetectGpsLocation =>
      'No se pudo detectar tu ubicación GPS — elige tu ciudad';

  @override
  String get postAdPleaseSelectCategoryCity =>
      'Selecciona una categoría y una ciudad';

  @override
  String get postAdAddAtLeastOnePhoto => 'Añade al menos una foto a tu anuncio';

  @override
  String get postAdEnterClearTitleAtLeast =>
      'Escribe un título claro (mínimo 3 caracteres)';

  @override
  String get postAdEnterValidPriceFreeVerify =>
      'Indica un precio válido o Gratis y verifica tu teléfono';

  @override
  String postAdDailyFreeLimitReachedMaxdailyfreeads(Object maxDailyFreeAds) {
    return 'Límite diario gratuito alcanzado ($maxDailyFreeAds anuncios/día)';
  }

  @override
  String postAdPersonalAccountsIncludeUpMaxdailyfreeads(
      Object maxDailyFreeAds, Object monthlyPremiumPriceMad) {
    return 'Las cuentas personales incluyen hasta $maxDailyFreeAds anuncios gratis al día. Pásate a Apolo Premium ($monthlyPremiumPriceMad MAD/mes con Google Pay) para publicar anuncios ilimitados, tener tienda Business e insignia de Verificado.';
  }

  @override
  String postAdSubscribeMonthlypremiumpricemadMadMoGoogle(
      Object monthlyPremiumPriceMad) {
    return 'Suscribirse ($monthlyPremiumPriceMad MAD/mes) • Google Pay';
  }

  @override
  String get postAdMaybeLater => 'Quizás luego';

  @override
  String get postAdPleaseSignPublishListing =>
      'Inicia sesión para publicar tu anuncio';

  @override
  String get postAdAvailableGreatConditionApolo =>
      'Disponible en muy buen estado en Apolo';

  @override
  String get postAdFailedPublishListing => 'No se pudo publicar tu anuncio';

  @override
  String get postAdCategoriesCitiesUnavailableRetry =>
      'Categorías y ciudades no disponibles. Reintentar';

  @override
  String get postAdUnlimitedDailyAdsApoloPremium =>
      'Anuncios diarios ilimitados · Apolo Premium';

  @override
  String postAdMaxdailyfreeadsMaxdailyfreeads2DailyLimitReached(
      Object maxDailyFreeAds,
      Object maxDailyFreeAds2,
      Object monthlyPremiumPriceMad) {
    return 'Límite diario de $maxDailyFreeAds/$maxDailyFreeAds2 alcanzado · Mejora tu plan ($monthlyPremiumPriceMad MAD)';
  }

  @override
  String postAdTodayTodaypostedadscountMaxdailyfreeadsFreeAds(
      Object todayPostedAdsCount, Object maxDailyFreeAds) {
    return 'Hoy: $todayPostedAdsCount/$maxDailyFreeAds anuncios gratis · Ilimitados con Premium';
  }

  @override
  String get postAdWhereAreYouListing => '¿Dónde vendes tu artículo?';

  @override
  String get postAdChooseCategoryCitySoNearby =>
      'Elige categoría y ciudad para que los compradores cercanos lo encuentren fácil';

  @override
  String get postAdAddClearPhotos => 'Añade fotos claras';

  @override
  String get postAdListingsRealClearPhotosSell =>
      'Los anuncios con fotos reales y nítidas se venden hasta 3 veces más rápido';

  @override
  String get postAdDescribeItem => 'Describe tu artículo';

  @override
  String get postAdClearTitleHonestDescriptionBuild =>
      'Un título claro y una descripción sincera dan confianza al comprador';

  @override
  String get postAdSetPriceContact => 'Pon precio y contacto';

  @override
  String get postAdSetFairPriceReviewListing =>
      'Elige un precio justo y revisa tu anuncio antes de publicarlo';

  @override
  String get postAdGpsLocationSet => 'Ubicación GPS fijada';

  @override
  String get postAdDetectAdLocationGps =>
      'Detectar ubicación del anuncio (GPS)';

  @override
  String get postAdTapAddPhotos => 'Toca para añadir fotos';

  @override
  String postAdAddMorePhotosTotalphotos8(Object totalPhotos) {
    return 'Añadir más fotos ($totalPhotos/8)';
  }

  @override
  String get postAdFirstPhotoWillBeUsed =>
      'La primera foto será la portada del anuncio';

  @override
  String get postAdGallery => 'Galería';

  @override
  String get postAdSelectedPhotos => 'Fotos seleccionadas';

  @override
  String get postAdCover => 'Portada';

  @override
  String get postAdListingTitle => 'Título del anuncio';

  @override
  String get postAdGreat => 'Genial ✓';

  @override
  String get postAdEGIphone15Pro => 'p. ej. iPhone 15 Pro Max 256GB como nuevo';

  @override
  String get postAdDetailedDescription => 'Descripción detallada';

  @override
  String get postAdMentionConditionIncludedAccessoriesKey =>
      'Cuenta el estado, accesorios incluidos y detalles importantes...';

  @override
  String get postAdSpecifications => 'Características';

  @override
  String get postAdPriceMad => 'Precio (MAD)';

  @override
  String get postAdEG2500 => 'p. ej. 2500';

  @override
  String get postAdHideNumber => 'Ocultar número';

  @override
  String get postAdListingPreview => 'Vista previa del anuncio';

  @override
  String get postAdPublishNow => 'Publicar ahora';

  @override
  String get postAdListingUpdated => 'Anuncio actualizado';

  @override
  String get postAdListingIsLive => '¡Tu anuncio ya está publicado!';

  @override
  String get postAdListingIsNowVisibleBuyers =>
      'Tu anuncio ya es visible para los compradores en Apolo.ma.';

  @override
  String get postAdNewListing => 'Tu nuevo anuncio';

  @override
  String get postAdBackHome => 'Volver al inicio';

  @override
  String get postAdPostAnotherListing => 'Publicar otro anuncio';

  @override
  String get privacyComplianceReportAiPolicyIssue =>
      'Denunciar problema de IA o normas';

  @override
  String get privacyComplianceSelectReasonSubmitThisReport =>
      'Selecciona un motivo para enviarlo de inmediato al equipo de Confianza y Seguridad:';

  @override
  String get privacyComplianceAdditionalDetailsOptional =>
      'Detalles adicionales (opcional)...';

  @override
  String get privacyComplianceSubmitReport => 'Enviar denuncia';

  @override
  String get privacyComplianceCouldNotSendReportPlease =>
      'No se pudo enviar la denuncia. Inténtalo de nuevo.';

  @override
  String get privacyComplianceReportSubmittedSuccessfully =>
      'Denuncia enviada correctamente ✓';

  @override
  String privacyComplianceLinkCopiedUrl(Object url) {
    return 'Enlace copiado: $url';
  }

  @override
  String get privacyComplianceConfirmAccountDeletion =>
      'Confirmar eliminación de cuenta';

  @override
  String get privacyComplianceAreYouSureYouWant =>
      '¿Seguro que quieres eliminar de forma permanente tu cuenta, datos personales, anuncios y mensajes de Apolo? Esta acción no se puede deshacer.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get privacyComplianceDeletePermanently => 'Eliminar definitivamente';

  @override
  String get privacyComplianceAccountDataHaveBeenDeleted =>
      'Tu cuenta y tus datos han sido eliminados.';

  @override
  String get privacyComplianceCouldNotConfirmDeletionYou =>
      'No se pudo confirmar la eliminación. Tu sesión sigue abierta. Inténtalo de nuevo.';

  @override
  String get privacyCompliancePrivacyPolicies => 'Privacidad y normas';

  @override
  String get privacyCompliancePrivacy => 'Privacidad';

  @override
  String get privacyCompliancePolicies => 'Normas';

  @override
  String get privacyComplianceDataDelete => 'Datos y baja';

  @override
  String get privacyComplianceUpdated2026Law0908 =>
      'Actualizado en 2026 · Ley 09-08 (CNDP)';

  @override
  String get privacyCompliancePrivacyFullyControl =>
      'Tu privacidad, siempre bajo tu control';

  @override
  String get privacyComplianceWeNeverSellPersonalData =>
      'Nunca vendemos tus datos personales. Tu información se usa únicamente para gestionar tus anuncios, chats seguros y notificaciones móviles en Apolo (ma.apolo.apoloMobile).';

  @override
  String get privacyComplianceDataWeCollect => 'Datos que recopilamos';

  @override
  String get privacyComplianceAccountIdentityNameEmailPhone =>
      '• Identidad de la cuenta: nombre, correo, teléfono o inicio de sesión seguro con Google / Apple.\n• Anuncios y tiendas: fotos, títulos, descripciones, precios en MAD y ciudad elegida.\n• Mensajería en tiempo real: mensajes de chat, archivos multimedia y reacciones entre compradores y vendedores.\n• Tokens push móviles (FCM / APNs): usados solo para enviar notificaciones del sistema y desactivados automáticamente al cerrar sesión.';

  @override
  String get privacyComplianceDevicePermissionsControls =>
      'Permisos y controles del dispositivo';

  @override
  String get privacyComplianceNotificationsOptionalOsAlertsNew =>
      '• Notificaciones: avisos opcionales para nuevos mensajes en iOS y Android; configurables en cualquier momento.\n• Cámara y fotos: se solicitan solo al subir fotos de anuncios o adjuntos en el chat.\n• Zona aproximada: filtro de distancia a nivel de ciudad sin rastreo GPS en segundo plano.';

  @override
  String get privacyComplianceAiSafetyAppReporting =>
      'Seguridad de IA y denuncias en la app';

  @override
  String get privacyComplianceSmartListingSearchToolsInclude =>
      'Las herramientas inteligentes de publicación y búsqueda incluyen denuncias directas desde la app para avisar al instante de sugerencias imprecisas de IA o anuncios abusivos.';

  @override
  String get privacyComplianceLegalRightsContact =>
      'Tus derechos legales y contacto';

  @override
  String get privacyComplianceUnderMoroccanLaw0908 =>
      'Según la Ley marroquí 09-08 y las normas de App Store / Google Play, tienes derecho a acceder, actualizar o eliminar definitivamente tus datos personales.\n• Correo oficial: support@apolo.ma / contact@apolo.ma\n• Web: https://apolo.ma';

  @override
  String get privacyComplianceReportAiPolicyIssueApp =>
      'Denunciar problema de IA o normas en la app';

  @override
  String get privacyComplianceOpenWebPrivacyPolicy =>
      'Abrir política de privacidad web';

  @override
  String get privacyComplianceTermsUseMarketplaceRules =>
      'Condiciones de uso y reglas del marketplace';

  @override
  String get privacyComplianceClearRulesSafeBuyingSelling =>
      'Reglas claras para comprar y vender seguro';

  @override
  String get privacyComplianceByUsingApoloYouAgree =>
      'Al usar Apolo, aceptas publicar anuncios reales, mantener un trato respetuoso en el chat y cumplir unas normas transparentes.';

  @override
  String get privacyComplianceAccountIntegrityVerifiedBadges =>
      'Integridad de la cuenta e insignias de Verificado';

  @override
  String get privacyComplianceAccountStoreDetailsMustRemain =>
      '• Los datos de tu cuenta y tienda deben ser reales y veraces.\n• Los sellos de Verificado y rangos de vendedor (de Bronce a Campeón) los otorga exclusivamente Apolo; está prohibida la suplantación.';

  @override
  String get privacyComplianceListingRulesProhibitedItems =>
      'Reglas de anuncios y artículos prohibidos';

  @override
  String get privacyComplianceListingsMustRepresentRealItems =>
      '• Los anuncios deben mostrar artículos o servicios reales con fotos auténticas y precios honestos.\n• Estrictamente prohibido: falsificaciones, armas, sustancias ilegales, medicamentos con receta, artículos robados y estafas con pagos por adelantado.';

  @override
  String get privacyComplianceSafeTransactionsChatConduct =>
      'Tratos seguros y conducta en el chat';

  @override
  String get privacyComplianceAlwaysInspectItemsPersonSafe =>
      '• Revisa siempre el artículo en persona en un lugar público seguro y evita adelantar dinero.\n• El spam, el acoso y los mensajes ofensivos suponen la suspensión inmediata; puedes bloquear o denunciar en cualquier momento.';

  @override
  String get privacyComplianceProSubscriptionsListingBoosts =>
      'Suscripciones Pro+ y destacados';

  @override
  String get privacyComplianceProPlansBoostUpgradesAre =>
      '• Los planes Pro+ y los destacados se facturan de forma transparente a través de tu cuenta de App Store o Google Play.\n• Cancela la renovación automática cuando quieras al menos 24 horas antes de que termine el periodo en los ajustes de tu tienda.';

  @override
  String get privacyComplianceOpenWebTermsPolicies =>
      'Abrir condiciones y políticas web';

  @override
  String get privacyComplianceInstantErasureAppStorePlay =>
      'Borrado inmediato · App Store y Google Play';

  @override
  String get privacyCompliancePermanentAccountDataDeletion =>
      'Eliminación definitiva de cuenta y datos';

  @override
  String get privacyComplianceEraseAccountAllAssociatedPersonal =>
      'Borra tu cuenta y todos tus datos personales directamente desde la app o mediante nuestro formulario web externo.';

  @override
  String get privacyComplianceWhatGetsPermanentlyDeleted =>
      'Qué se elimina definitivamente';

  @override
  String get privacyComplianceProfileCredentialsNameEmailPhone =>
      '• Credenciales de perfil (nombre, correo, teléfono y accesos vinculados).\n• Todos los anuncios publicados, fotos subidas y datos de la tienda.\n• Historial de chats, favoritos guardados y tokens activos de notificaciones push.';

  @override
  String get privacyComplianceDeleteMyAccountNowApp =>
      'Eliminar mi cuenta ahora (en la app)';

  @override
  String get privacyComplianceSignDeleteAccountDirectlyApp =>
      'Inicia sesión para eliminar tu cuenta directamente en la app, o usa el enlace web externo de abajo.';

  @override
  String get privacyComplianceExternalWebDataDeletionLink =>
      'Enlace web externo para eliminar datos';

  @override
  String get proPlusRecurringBillingCancelAnytimePayment =>
      'Facturación periódica. Cancela cuando quieras. El pago se cargará en tu cuenta de Google Pay / tienda al confirmar la compra y se renovará automáticamente salvo que lo desactives al menos 24 horas antes del final del periodo actual.\nTodos los datos personales se tratan conforme a los ';

  @override
  String get proPlusTermsConditions => 'términos y condiciones';

  @override
  String get proPlusAnd => ' y la ';

  @override
  String get proPlusPrivacyPolicy => 'política de privacidad';

  @override
  String get proPlusSubscription => 'Suscripción';

  @override
  String get proPlusCancelPremiumSubscription =>
      '¿Cancelar tu suscripción Premium?';

  @override
  String get proPlusAutoRenewalWillBeTurned =>
      'Se desactivará la renovación automática y tu tienda y anuncios seguirán seguros.';

  @override
  String get proPlusCancelMySubscription => 'Cancelar mi suscripción';

  @override
  String get proPlusKeepPremium => 'Mantener Premium';

  @override
  String get proPlusYouUsePremium => 'Ya tienes Premium';

  @override
  String get proPlusGetPremium => 'Hazte Premium';

  @override
  String get proPlusYouHaveUnlimitedAccessAll =>
      'Tienes acceso ilimitado a todas las ventajas Premium';

  @override
  String get proPlusGetUnlimitedAccessAllPremium =>
      'Consigue acceso ilimitado a todas las ventajas Premium';

  @override
  String get proPlusCheckedAccountActivePurchases =>
      'Hemos comprobado las compras activas de tu cuenta.';

  @override
  String get proPlusHowTrialWorks => 'Cómo funciona tu prueba gratis';

  @override
  String proPlusUnlimitedFreeAccess3Days(Object monthlyPremiumPriceMad) {
    return 'Acceso ilimitado gratis durante 3 días, luego solo $monthlyPremiumPriceMad MAD/mes con Google Pay';
  }

  @override
  String get proPlusGetInstantAccessSeeHow =>
      'Obtén acceso al instante y descubre cómo Pro Plus impulsa tus ventas.';

  @override
  String get proPlusDay2 => 'Día 2';

  @override
  String get proPlusWeLlRemindYouNotification =>
      'Te enviaremos una notificación para recordarte que tu prueba termina pronto.';

  @override
  String get proPlusDay3 => 'Día 3';

  @override
  String get proPlusYouLlBeChargedDay =>
      'Se te cobrará el día 3; cancela gratis antes cuando quieras.';

  @override
  String get proPlusViewAllPlans => 'Ver todos los planes';

  @override
  String get proPlusRestorePurchases => 'Restaurar compras';

  @override
  String get proPlusStartFree3DayTrial => 'Empezar prueba gratis de 3 días';

  @override
  String get proPlusPaymentVerificationFailed =>
      'No se pudo verificar el pago.';

  @override
  String get proPlusProPlusActivatedStoreIs =>
      '¡Pro Plus activado! Tu tienda ya está verificada';

  @override
  String get proPlusCouldNotLaunchGooglePay =>
      'No se pudo abrir Google Pay en este dispositivo.';

  @override
  String get proPlusPayGooglePay => 'Pagar con Google Pay';

  @override
  String get proPlusSave25 => 'Ahorra un 25%';

  @override
  String get proPlusLifetime => 'De por vida';

  @override
  String get proPlusBasic => 'Básico';

  @override
  String get proPlus12Months => '12 meses';

  @override
  String get proPlusOneTime => 'Pago único';

  @override
  String get proPlus1Month => '1 mes';

  @override
  String get proPlusMad => 'MAD';

  @override
  String get proPlusPaywall => 'Planes';

  @override
  String get proPlusUnlockFullAccess => 'Desbloquea el acceso completo';

  @override
  String get proPlusUnlimitedAccessAllFeaturesTemplates =>
      'Acceso ilimitado a todas las herramientas y plantillas';

  @override
  String get proPlusOfficialBusinessStoreBlueVerified =>
      'Tienda oficial Business + insignia azul de Verificado';

  @override
  String get proPlusUnlimitedDailyListingsInstead5 =>
      'Anuncios diarios ilimitados (en vez de 5/día) + 12 fotos';

  @override
  String get proPlus5FreeMonthlyVipBoosts =>
      '5 destacados VIP gratis al mes + estadísticas Pro y respuestas rápidas';

  @override
  String proPlusSubscribePricedisplayMadGooglePay(Object priceDisplay) {
    return 'Suscribirse por $priceDisplay MAD • Google Pay';
  }

  @override
  String get proPlusNoThankYou => 'No, gracias';

  @override
  String get profileCouldNotLoadListingsPull =>
      'No se pudieron cargar los anuncios. Desliza para reintentar.';

  @override
  String get profileMyAccount => 'Mi cuenta';

  @override
  String get profileSettingsSupport => 'Ajustes y ayuda';

  @override
  String get profileSignManageListingsSavedItems =>
      'Inicia sesión para gestionar tus anuncios, favoritos y chats al instante.';

  @override
  String get profileSignViewProfile => 'Inicia sesión para ver tu perfil';

  @override
  String get welcomeCreateAccountButton => 'Crear una cuenta';

  @override
  String get profileLightMode => 'Modo claro';

  @override
  String get profileDarkMode => 'Modo oscuro';

  @override
  String get profileListings => 'Anuncios';

  @override
  String get profileLikes => 'Me gusta';

  @override
  String get profileSaved => 'Guardados';

  @override
  String get shareProfileButton => 'Compartir perfil';

  @override
  String get profileMyListings => 'Mis anuncios';

  @override
  String get profileProInsightsBoost => 'Estadísticas Pro y destacar';

  @override
  String profileUpgradeApoloPremiumMonthlypremiumpricemadMad(
      Object monthlyPremiumPriceMad) {
    return 'Pásate a Apolo Premium · $monthlyPremiumPriceMad MAD/mes';
  }

  @override
  String get profileBusinessStoreVerifiedBadgeUnlimited =>
      'Tienda Business + insignia Verificado + anuncios diarios ilimitados con Google Pay.';

  @override
  String get profileViewStore => 'Ver tienda';

  @override
  String get profileEditStore => 'Editar tienda';

  @override
  String get profileQuickReplies => 'Respuestas rápidas';

  @override
  String get profileNoListingsYet => 'Aún no tienes anuncios';

  @override
  String get profilePublishFirstListingShowcaseIt =>
      'Publica tu primer anuncio para mostrarlo aquí.';

  @override
  String get profilePostListing => 'Publicar un anuncio';

  @override
  String get profileTotalViews => 'Visitas totales';

  @override
  String get profileActiveListings => 'Anuncios activos';

  @override
  String get profileAvgListing => 'Media / anuncio';

  @override
  String get profileBoostedListings => 'Anuncios destacados';

  @override
  String get profileCallTaps => 'Toques en llamar';

  @override
  String get profileCustomerChats => 'Chats de clientes';

  @override
  String get profileDirectOrders => 'Pedidos directos';

  @override
  String get profileFreeVipCredits => 'Créditos VIP gratis';

  @override
  String get profileUnlockCallOrderStatsPro =>
      'Desbloquea estadísticas de llamadas y pedidos + insignia PRO+';

  @override
  String get profileGet3FreeVipBoosts =>
      'Consigue 3 destacados VIP gratis al mes y visibilidad prioritaria.';

  @override
  String get profileViewsBreakdown => 'Desglose de visitas';

  @override
  String get profileLive => 'En activo';

  @override
  String get profilePublishFirstListingTrackViews =>
      'Publica tu primer anuncio para seguir aquí sus visitas y rendimiento.';

  @override
  String get profileTopPerformingListings => 'Anuncios con más éxito';

  @override
  String get profileViews => 'visitas';

  @override
  String get profileSalesTip => 'Consejo de venta';

  @override
  String get profileAddClearPhotosFairPrice =>
      'Pon fotos nítidas y un buen precio en tu primer anuncio para atraer compradores rápido.';

  @override
  String get profileRefreshingPhotosBoostingTopListing =>
      'Renovar las fotos o destacar tu mejor anuncio ayuda a venderlo mucho antes.';

  @override
  String get profileEditListing => 'Editar anuncio';

  @override
  String get profileBoostThisListing => 'Destacar este anuncio';

  @override
  String get profileDeleteListing => 'Eliminar anuncio';

  @override
  String get profileCouldNotDeleteListingPlease =>
      'No se pudo eliminar el anuncio. Inténtalo de nuevo.';

  @override
  String get profileDeleteThisListing => '¿Eliminar este anuncio?';

  @override
  String get profileThisListingWillBePermanently =>
      'Este anuncio desaparecerá de forma permanente de tu perfil y de las búsquedas.';

  @override
  String get profileListingDeletedSuccessfully =>
      'Anuncio eliminado correctamente';

  @override
  String get scanProfileCodeThisIsOwnProfile => 'Este es tu propio perfil';

  @override
  String scanProfileCodeApoloMemberSellerid(Object sellerId) {
    return 'Miembro de Apolo #$sellerId';
  }

  @override
  String get scanProfileCodeScannedCode => 'Código escaneado';

  @override
  String get scanProfileCodeCodeDetected => 'Código detectado';

  @override
  String get scanProfileCodeOpenLink => 'Abrir enlace';

  @override
  String get scanProfileCodeScanAgain => 'Escanear de nuevo';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisBrowser =>
      'La linterna no está disponible en este navegador';

  @override
  String get scanProfileCodeFlashlightIsUnavailableThisCamera =>
      'La linterna no está disponible en esta cámara';

  @override
  String get scanProfileCodeCouldNotToggleFlashlightRight =>
      'No se pudo cambiar la linterna ahora mismo';

  @override
  String get scanProfileCodeNoQrCodeDetectedSelected =>
      'No se detectó ningún código QR en la imagen elegida';

  @override
  String get scanProfileCodeEnterCode => 'Introducir código';

  @override
  String get scanProfileCodeCouldNotOpenPhotoLibrary =>
      'No se pudo abrir la galería de fotos';

  @override
  String get scanProfileCodeScanQrCode => 'Escanear código QR';

  @override
  String get scanProfileCodePickQrImage => 'Elegir imagen QR';

  @override
  String get scanProfileCodeTapEnableCamera => 'Toca para activar la cámara';

  @override
  String get scanProfileCodeEnterCodeManually =>
      'Introducir código manualmente';

  @override
  String get scanProfileCodePleaseEnterLinkHandle =>
      'Introduce un enlace o @usuario';

  @override
  String get scanProfileCodePasteApoloProfileLinkEnter =>
      'Pega un enlace de perfil de Apolo o escribe @usuario';

  @override
  String get scanProfileCodeOpenProfile => 'Abrir perfil';

  @override
  String get searchRecommended => 'Recomendados';

  @override
  String get searchNewest => 'Más recientes';

  @override
  String get searchLowestPrice => 'Más baratos';

  @override
  String get searchHighestPrice => 'Más caros';

  @override
  String get searchMostViewed => 'Más vistos';

  @override
  String get searchFilterSort => 'Filtrar y ordenar';

  @override
  String get resetButton => 'Restablecer';

  @override
  String get searchSortBy => 'Ordenar por';

  @override
  String get searchAllMorocco => 'Todo Marruecos';

  @override
  String get searchPriceRangeMad => 'Rango de precio (MAD)';

  @override
  String get searchMinPrice => 'Precio mín.';

  @override
  String get searchMaxPrice => 'Precio máx.';

  @override
  String get searchNegotiableListingsOnly => 'Solo precio negociable';

  @override
  String get searchApplyFilters => 'Aplicar filtros';

  @override
  String get searchSignSaveSearchesListings =>
      'Inicia sesión para guardar búsquedas y anuncios';

  @override
  String get searchSaved => 'Búsqueda guardada';

  @override
  String get searchUnableSaveSearchRightNow =>
      'No se pudo guardar la búsqueda ahora mismo';

  @override
  String get searchSaveSearch => 'Guardar búsqueda';

  @override
  String get searchNoSavedListingsYet => 'Aún no tienes anuncios guardados';

  @override
  String get searchTapHeartAnyListingSave =>
      'Toca el corazón en cualquier anuncio para guardarlo aquí';

  @override
  String get searchFilter => 'Filtrar';

  @override
  String get searchAllCategories => 'Todas las categorías';

  @override
  String get searchAllAreas => 'Todas las zonas';

  @override
  String get searchSetArea => 'Elegir zona';

  @override
  String get searchFeedView => 'Vista lista';

  @override
  String get searchGridView => 'Vista cuadrícula';

  @override
  String get personalAccountBadge => 'Personal';

  @override
  String get businessAccountBadge => 'Business';

  @override
  String searchNoListingsWithinZoneradiuskmKm(Object zoneRadiusKm, Object s) {
    return 'No hay anuncios a menos de $zoneRadiusKm km de $s.';
  }

  @override
  String get searchTryAnotherCategoryBroadenFilters =>
      'Prueba con otra categoría o amplía los filtros.';

  @override
  String get searchResetFilters => 'Borrar filtros';

  @override
  String get sellerProfileSellerPhoneNumberNotAvailable =>
      'El teléfono del vendedor no está disponible';

  @override
  String get sellerProfileSelectListingMessageThisSeller =>
      'Elige un anuncio para escribir a este vendedor.';

  @override
  String get sellerProfileReportSeller => 'Denunciar vendedor';

  @override
  String get sellerProfileBlockSeller => 'Bloquear vendedor';

  @override
  String get sellerProfileSellerBlockedSuccessfully =>
      'Vendedor bloqueado correctamente';

  @override
  String get sellerProfileFollowers => 'Seguidores';

  @override
  String get sellerProfileRating => 'Valoración';

  @override
  String sellerProfileStorecategorylabelCityStorehours(
      Object storeCategoryLabel, Object city, Object storeHours) {
    return '$storeCategoryLabel · $city · $storeHours';
  }

  @override
  String sellerProfileIndividualSellerCityDirectChat(Object city) {
    return 'Vendedor particular en $city · Respuesta directa por chat.';
  }

  @override
  String get sellerProfileVisitStore => 'Visitar tienda';

  @override
  String sellerProfileListingsSellerads(Object sellerAds) {
    return 'Anuncios ($sellerAds)';
  }

  @override
  String sellerProfileReviewsCount(Object count) {
    return 'Valoraciones ($count)';
  }

  @override
  String get sellerProfileTrustInfo => 'Confianza e info';

  @override
  String get sellerProfileNoListingsAvailableRightNow =>
      'No hay anuncios disponibles ahora mismo';

  @override
  String get sellerProfile3DaysAgo => 'Hace 3 días';

  @override
  String get sellerProfileVeryReliableSellerItemMatched =>
      'Vendedor muy fiable, el artículo era tal cual las fotos y trato genial en todo momento.';

  @override
  String get sellerProfile1WeekAgo => 'Hace 1 semana';

  @override
  String get sellerProfileSmoothBuyingExperienceInspectedBefore =>
      'Compra perfecta, lo revisé antes de pagar. ¡Totalmente recomendable!';

  @override
  String get sellerProfile2WeeksAgo => 'Hace 2 semanas';

  @override
  String get sellerProfileHonestRespectfulSellerLetMe =>
      'Vendedor honesto y amable. Me dejó probar el portátil con calma.';

  @override
  String get sellerProfile1MonthAgo => 'Hace 1 mes';

  @override
  String get sellerProfileGreatTransactionFullTrustFast =>
      'Trato de 10 y máxima confianza. Responde rapidísimo por el chat de Apolo.';

  @override
  String sellerProfileCountVerifiedReviews(Object count) {
    return '$count valoraciones verificadas';
  }

  @override
  String get sellerProfileGovernmentIdVerified =>
      'Documento de identidad verificado';

  @override
  String get sellerProfileOfficialIdentityDocumentReviewedVerified =>
      'Documento oficial revisado y verificado por el equipo de Confianza de Apolo.';

  @override
  String get sellerProfileVerifiedPhoneNumber => 'Teléfono verificado';

  @override
  String get sellerProfilePhoneNumberConfirmedViaSms =>
      'Número de teléfono confirmado mediante código SMS OTP.';

  @override
  String get sellerProfileApoloSafetyProtection =>
      'Protección y seguridad Apolo';

  @override
  String get sellerProfileWeRecommendInspectingItemPerson =>
      'Te recomendamos revisar el artículo en persona antes de hacer cualquier pago.';

  @override
  String get sellerProfileAvailableDeliveryMethods =>
      'Opciones de entrega disponibles';

  @override
  String sellerProfileHandHandPickupCityInsured(Object city) {
    return 'Entrega en mano en $city o envío urgente asegurado previo acuerdo.';
  }

  @override
  String get accountCenterSwitchPersonalAccount => 'Cambiar a cuenta personal';

  @override
  String get accountCenterReturnPersonalAccount =>
      '¿Volver a una cuenta personal?';

  @override
  String get accountCenterBusinessStorePageWillBe =>
      'Tu página de tienda Business quedará en pausa. Podrás reactivarla cuando quieras.';

  @override
  String get accountCenterConfirmSwitch => 'Confirmar cambio';

  @override
  String get accountCenterSwitchedPersonalAccount =>
      'Has cambiado a cuenta personal.';

  @override
  String get accountCenterCouldNotSwitchAccountType =>
      'No se pudo cambiar el tipo de cuenta. Inténtalo de nuevo.';

  @override
  String get accountCenterApoloAccount => 'Cuenta de Apolo';

  @override
  String get accountCenterPersonalDetails => 'Datos personales';

  @override
  String get accountCenterEmailPhone => 'Correo y teléfono';

  @override
  String get accountCenterAccountTypePreferences =>
      'Tipo de cuenta y preferencias';

  @override
  String get accountCenterPasswordSecurity => 'Contraseña y seguridad';

  @override
  String get accountCenterResetPassword => 'Restablecer contraseña';

  @override
  String get accountCenterBusinessStore => 'Business y tienda';

  @override
  String get accountCenterEditStoreProfile => 'Editar perfil de tienda';

  @override
  String get accountCenterSwitchBusinessAccount => 'Cambiar a cuenta Business';

  @override
  String get accountCenterAccountOwnership => 'Propiedad de la cuenta';

  @override
  String get accountCenterDeleteAccountData => 'Eliminar cuenta y datos';

  @override
  String get accountCenterManageApoloAccount => 'Gestiona tu cuenta de Apolo';

  @override
  String get accountCenterSignManageSecurityPersonalDetails =>
      'Inicia sesión para gestionar tu seguridad, datos personales y tu tienda.';

  @override
  String get logInButton => 'Entrar';

  @override
  String get settingsAppDataAppDataRefreshedSuccessfully =>
      'Datos de la app actualizados correctamente.';

  @override
  String get settingsAppDataCouldNotRefreshDataCheck =>
      'No se pudieron actualizar los datos. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get settingsAppDataAppDataSync => 'Datos y sincronización';

  @override
  String get settingsAppDataSystemInformationLocalSyncStatus =>
      'Información del sistema y estado de sincronización con Apolo.ma.';

  @override
  String get settingsAppDataApplicationStatus => 'Estado de la aplicación';

  @override
  String get settingsAppDataAppVersion => 'Versión de la app';

  @override
  String get settingsAppDataServer => 'Servidor';

  @override
  String get settingsAppDataSyncedCategories => 'Categorías sincronizadas';

  @override
  String get settingsAppDataSyncedCities => 'Ciudades sincronizadas';

  @override
  String get settingsAppDataActiveZone => 'Zona activa';

  @override
  String get settingsAppDataOpenSourceLicenses => 'Licencias de código abierto';

  @override
  String get settingsAppDataRefreshDataNow => 'Actualizar datos ahora';

  @override
  String get settingsAppearanceAppearance => 'Apariencia';

  @override
  String get settingsAppearanceChooseHowApoloLooksSwitch =>
      'Elige cómo se ve Apolo. Cambia entre modo claro, modo oscuro o ajústalo automáticamente según tu dispositivo.';

  @override
  String get settingsAppearanceCleanWhiteSurfacesCrispDaylight =>
      'Fondos claros y limpios con contraste nítido de día';

  @override
  String get settingsAppearanceEasyEyesLowLightSaves =>
      'Cómodo para la vista con poca luz y ahorra batería';

  @override
  String get settingsAppearanceSystemDefault => 'Predeterminado del sistema';

  @override
  String get settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme =>
      'Se adapta automáticamente al tema de tu móvil o navegador';

  @override
  String settingsBlockedAccountsUnblockedName(Object name) {
    return 'Has desbloqueado a $name';
  }

  @override
  String get settingsBlockedAccountsBlockedAccounts => 'Cuentas bloqueadas';

  @override
  String get settingsBlockedAccountsNoBlockedAccountsYet =>
      'No tienes cuentas bloqueadas';

  @override
  String get settingsBlockedAccountsUsersStoresYouBlockFrom =>
      'Los usuarios o tiendas que bloquees desde chats o anuncios aparecerán aquí para que puedas desbloquearlos cuando quieras.';

  @override
  String get settingsBlockedAccountsYouCanUnblockAnyUser =>
      'Puedes desbloquear a cualquier usuario o tienda en cualquier momento.';

  @override
  String get settingsBlockedAccountsBlockedStore => 'Tienda bloqueada';

  @override
  String get settingsBlockedAccountsBlockedUser => 'Usuario bloqueado';

  @override
  String get settingsBugReportQuickTrigger => 'Acceso rápido';

  @override
  String get settingsBugReportDiagnosticsSummary => 'Resumen de diagnóstico';

  @override
  String get settingsBugReportPlatform => 'Plataforma';

  @override
  String get settingsBugReportActiveLanguage => 'Idioma activo';

  @override
  String get settingsBugReportHelpSupport => 'Ayuda y soporte';

  @override
  String get settingsLanguageCouldNotSaveLanguagePlease =>
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get settingsLanguageAppLanguage => 'Idioma de la app';

  @override
  String get settingsLanguageChooseLanguageAppInterfaceListings =>
      'Elige el idioma de la interfaz y los anuncios. El cambio se aplica al instante en toda la app.';

  @override
  String get settingsRateAppNeedsWork => 'Mejorar';

  @override
  String get settingsRateAppFair => 'Normal';

  @override
  String get settingsRateAppGreat => 'Muy bien';

  @override
  String get settingsRateAppAwesome => '¡Genial!';

  @override
  String get settingsRateAppSelectStars => 'Elige las estrellas';

  @override
  String get settingsRateAppPleaseSelect15Stars =>
      'Selecciona de 1 a 5 estrellas.';

  @override
  String get settingsRateAppRateApp => 'Valorar la app';

  @override
  String get settingsRateAppHowIsExperienceApoloMa =>
      '¿Qué tal tu experiencia con Apolo.ma?';

  @override
  String get settingsRateAppAddQuickNoteOptional =>
      'Añade un comentario breve (opcional)...';

  @override
  String settingsRateAppThankYouRatingUsRating(Object rating) {
    return '¡Gracias por valorarnos con $rating/5!';
  }

  @override
  String get settingsRateAppSubmitRating => 'Enviar valoración';

  @override
  String get settingsRateAppVisitApoloMa => 'Visitar Apolo.ma';

  @override
  String get settingsSavedAdsCouldNotRemoveSavedListing =>
      'No se pudo quitar el anuncio guardado. Inténtalo de nuevo.';

  @override
  String get settingsSavedAdsSignViewSavedListings =>
      'Inicia sesión para ver tus anuncios guardados';

  @override
  String get settingsSavedAdsSaveListingsYouLikeRevisit =>
      'Guarda los anuncios que te gusten para verlos cuando quieras.';

  @override
  String get settingsSavedAdsCouldNotLoadSavedListings =>
      'No se pudieron cargar tus anuncios guardados';

  @override
  String get settingsSavedAdsCheckInternetConnectionTryAgain =>
      'Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get settingsSavedAdsTapFavoriteIconAnyListing =>
      'Toca el icono de favorito en cualquier anuncio para guardarlo aquí.';

  @override
  String settingsShareAppCheckOutApoloMaMorocco(Object shareUrl) {
    return 'Mira Apolo.ma — el marketplace de anuncios y tiendas de Marruecos: $shareUrl';
  }

  @override
  String get settingsShareAppShareApp => 'Compartir la app';

  @override
  String get settingsShareAppMoroccoSMarketplaceClassifiedsOfficial =>
      'El marketplace de compraventa y tiendas oficiales en Marruecos. Compártelo con amigos y familia.';

  @override
  String settingsShareAppAppLinkCopiedShareurl(Object shareUrl) {
    return 'Enlace de la app copiado: $shareUrl';
  }

  @override
  String get settingsShareAppShareNow => 'Compartir ahora';

  @override
  String get settingsShareAppCopyLink => 'Copiar enlace';

  @override
  String get settingsShareAppShareMyQrProfile => 'Compartir mi código QR';

  @override
  String get settingsSuggestionPleaseEnterSuggestionAtLeast =>
      'Escribe una sugerencia de al menos 5 caracteres.';

  @override
  String get settingsSuggestionCouldNotSendOverNetwork =>
      'No se pudo enviar por red ahora mismo. Reintenta o envíala por correo.';

  @override
  String get settingsSuggestionCopiedSupportApoloMa =>
      'Copiado: support@apolo.ma';

  @override
  String get settingsSuggestionFeature => 'Función';

  @override
  String get settingsSuggestionDesign => 'Diseño';

  @override
  String get settingsSuggestionPerformance => 'Rendimiento';

  @override
  String get settingsSuggestionOther => 'Otro';

  @override
  String get settingsSuggestionMakeSuggestion => 'Enviar una sugerencia';

  @override
  String get settingsSuggestionShareIdeasHelpUsImprove =>
      'Comparte tus ideas para ayudarnos a mejorar Apolo.ma.';

  @override
  String get settingsSuggestionTopic => 'Tema';

  @override
  String get settingsSuggestionYourSuggestion => 'Tu sugerencia';

  @override
  String get settingsSuggestionWriteIdeaHere => 'Escribe aquí tu idea...';

  @override
  String get settingsSuggestionThankYouSuggestionHasBeen =>
      '¡Gracias! Hemos recibido tu sugerencia.';

  @override
  String get settingsSuggestionSubmitSuggestion => 'Enviar sugerencia';

  @override
  String get settingsSuggestionEmailSupportApoloMa =>
      'Escribir a support@apolo.ma';

  @override
  String get settingsZoneMarketplaceZone => 'Zona de búsqueda';

  @override
  String get logOutButton => 'Salir';

  @override
  String get settingsLogOutAccount => '¿Salir de tu cuenta?';

  @override
  String get settingsYouCanSignBackAnytime =>
      'Puedes volver a entrar cuando quieras para ver tus anuncios y mensajes.';

  @override
  String get settingsProActive => 'PRO+ activo';

  @override
  String get settingsNotSubscribed => 'Sin suscripción';

  @override
  String get settingsVipBoostCredits => 'Créditos de destacado VIP';

  @override
  String get settingsPrivacyTerms => 'Privacidad y condiciones';

  @override
  String get settingsAppDataLicenses => 'Datos de la app y licencias';

  @override
  String get settingsActivity => 'Ajustes y actividad';

  @override
  String get settingsNoMatchingSettings => 'No hay ajustes que coincidan';

  @override
  String get settingsTryAnotherKeywordSuchAs =>
      'Prueba con otra palabra como Guardados, Idioma o Pro+.';

  @override
  String get settingsYourAccount => 'Tu cuenta';

  @override
  String get settingsHowYouUseApolo => 'Cómo usas Apolo';

  @override
  String get settingsSubscriptions => 'Suscripciones';

  @override
  String get settingsCommunityPrivacy => 'Comunidad y privacidad';

  @override
  String get settingsSupport => 'Ayuda';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsPasswordSecurityPersonalDetailsStore =>
      'Contraseña, seguridad, datos personales, tienda y Business';

  @override
  String get shareProfileProfileLinkCopied => 'Enlace del perfil copiado';

  @override
  String shareProfileCheckOutNameHandleApolo(
      Object name, Object handle, Object url) {
    return 'Mira el perfil de $name ($handle) en Apolo.ma:\n$url';
  }

  @override
  String get shareProfileShareLink => 'Compartir enlace';

  @override
  String get shareProfileQrCodeIsPrivateIf =>
      'Tu código QR es privado. Si lo compartes con alguien, podrá escanearlo con su cámara para añadirte como contacto.';

  @override
  String get shareProfileScanCode => 'Escanear código';

  @override
  String get storeDetailReportStore => 'Denunciar tienda';

  @override
  String get storeDetailStoreBlocked => 'Tienda bloqueada';

  @override
  String get storeDetailBlockStore => 'Bloquear tienda';

  @override
  String get storeDetailDirectStoreOrder => 'Pedido directo a tienda';

  @override
  String get storeDetailSelectItem => 'Seleccionar artículo';

  @override
  String get storeDetailFullName => 'Nombre completo';

  @override
  String get storeDetailDeliveryAddress => 'Dirección de entrega';

  @override
  String get storeDetailOrderNotes => 'Notas del pedido';

  @override
  String get storeDetailConfirmOrder => 'Confirmar pedido';

  @override
  String get storeDetailOrderSubmittedSuccessfully =>
      'Pedido enviado correctamente';

  @override
  String get storeDetailStoreNotFound => 'Tienda no encontrada';

  @override
  String get storeDetailCheckLinkBrowseVerifiedStores =>
      'Comprueba el enlace o explora las tiendas verificadas.';

  @override
  String get storeDetailOrderNow => 'Pedir ahora';

  @override
  String storeDetailOpenWorkinghours(Object workingHours) {
    return 'Abierto · $workingHours';
  }

  @override
  String storeDetailClosedWorkinghours(Object workingHours) {
    return 'Cerrado · $workingHours';
  }

  @override
  String get storeDetailOpenGoogleMaps => 'Abrir en Google Maps';

  @override
  String get storeDetailOrder => 'Pedir';

  @override
  String get storeDetailProducts => 'Productos';

  @override
  String get verifiedBadgeLabel => 'Verificado';

  @override
  String get storeDetailDelivery => 'Envío';

  @override
  String get storeDetailStoreCatalog => 'Catálogo de la tienda';

  @override
  String storesTotalstoresVerifiedOfficialStores(Object totalStores) {
    return '$totalStores tiendas oficiales verificadas';
  }

  @override
  String get storesSearchOfficialStores => 'Buscar tiendas oficiales...';

  @override
  String get storesMostProducts => 'Más productos';

  @override
  String get storesTopRated => 'Mejor valoradas';

  @override
  String get storesNoMatchingStores => 'No se encontraron tiendas';

  @override
  String get storesTryAnotherKeywordReloadVerified =>
      'Prueba con otra palabra o recarga la lista de tiendas verificadas.';

  @override
  String get storesItems => 'artículos';

  @override
  String get storesVisit => 'Visitar';

  @override
  String get supportCouldNotOpenMailApp =>
      'No se pudo abrir tu app de correo. Escribe manualmente a support@apolo.ma.';

  @override
  String get supportHowCanWeHelpYou => '¿En qué podemos ayudarte?';

  @override
  String get supportExplainIssueStepsBeforeIt =>
      'Cuéntanos el problema y qué hiciste justo antes. Puedes adjuntar una captura ocultando tus datos personales.';

  @override
  String get supportDirectContact => 'Contacto directo';

  @override
  String get supportOpenMailApp => 'Abrir app de correo';

  @override
  String get supportNoEmailIsSentAutomatically =>
      'No se envía ningún correo automáticamente. Revísalo y envíalo desde tu app de correo.';

  @override
  String get supportSafetyReminder => 'Recordatorio de seguridad';

  @override
  String get supportNeverSharePasswordVerificationCode =>
      'Nunca compartas con nadie tu contraseña, código de verificación ni datos de pago.';

  @override
  String get welcomeUnableStartGoogleSignRight =>
      'No se puede iniciar sesión con Google ahora mismo.';

  @override
  String get welcomeContinueGoogle => 'Continuar con Google';

  @override
  String get welcomeOr => 'o';

  @override
  String get welcomeIHaveAccount => 'Ya tengo cuenta';

  @override
  String get welcomeNewOfferReceivedListing =>
      '¡Has recibido una nueva oferta en tu anuncio!';

  @override
  String get welcomeY => 'Y';

  @override
  String get welcomeYassineCasablanca => 'Yassine • Casablanca';

  @override
  String get welcomeYesAvailableWelcome => '¡Sí, sigue disponible!';

  @override
  String get accommodationCardSintraPortugal => 'Sintra, Portugal';

  @override
  String get accommodationCardExclusiveDeal => 'Oferta exclusiva';

  @override
  String get adCardVip => 'VIP';

  @override
  String get safetyReportMessage => 'Denunciar mensaje';

  @override
  String get safetyReportListing => 'Denunciar anuncio';

  @override
  String get safetyReportUser => 'Denunciar usuario';

  @override
  String get safetyAlsoBlockThisAccount => 'Bloquear también esta cuenta';

  @override
  String get safetySubmitReport => 'Enviar denuncia';

  @override
  String get safetyReportSubmittedSuccessfully =>
      'Denuncia enviada correctamente';

  @override
  String get safetyBlockedAccounts => 'Cuentas bloqueadas';

  @override
  String get boostCouldNotCompletePayment => 'No se pudo completar el pago';

  @override
  String get boostListingBoosted => '¡Anuncio destacado!';

  @override
  String get boostPaymentNotConfirmedContactSupport =>
      'Pago no confirmado. Contacta con soporte antes de reintentarlo.';

  @override
  String get boostVipBoostActivatedUsingPro =>
      '¡Destacado VIP activado con tu crédito Pro+!';

  @override
  String get boostListing => 'Destaca tu anuncio';

  @override
  String boostActivateFreeVipProVipboostcredits(Object vipBoostCredits) {
    return 'Activar VIP gratis con Pro+ ($vipBoostCredits)';
  }

  @override
  String get boostGet3FreeVipBoosts =>
      'Consigue 3 destacados VIP gratis al mes con Apolo Pro+';

  @override
  String get boostPlansAreCurrentlyUnavailablePlease =>
      'Los planes no están disponibles ahora mismo. Inténtalo más tarde.';

  @override
  String get boostInstantWebCheckoutIsEnabled =>
      'El pago web instantáneo está activado en tu cuenta.';

  @override
  String get boostActivateBoostNow => 'Activar destacado ahora';

  @override
  String get chatUtilsYesterday => 'Ayer';

  @override
  String get guestFavoriteBadge => 'Favorito entre huéspedes';

  @override
  String get exploreListingCardContactSeller => 'Contactar';

  @override
  String get marketplaceZoneCouldNotAutoDetectLocation =>
      'No se pudo detectar tu ubicación automáticamente — elige tu ciudad abajo';

  @override
  String get marketplaceZoneMarketplaceLocation => 'Ubicación de búsqueda';

  @override
  String get marketplaceZoneOnlySeeListingsInsideLocal =>
      'Ver solo anuncios dentro de tu zona';

  @override
  String get marketplaceZoneSearchNeighborhoodCityAddress =>
      'Buscar barrio, ciudad, dirección...';

  @override
  String get marketplaceZoneNationwide => 'Todo el país';

  @override
  String get marketplaceZoneDetectMyLocationAutomatically =>
      'Detectar mi ubicación automáticamente';

  @override
  String get marketplaceZoneDistanceRadius => 'Radio de distancia';

  @override
  String get marketplaceZoneAllMorocco => 'Todo Marruecos';

  @override
  String get marketplaceZoneSelectCity => 'Elegir ciudad';

  @override
  String get marketplaceZoneApplyZone => 'Aplicar zona';

  @override
  String quickRepliesLimitReachedMaxallowedUpgradePro(Object maxAllowed) {
    return 'Límite alcanzado ($maxAllowed). ¡Pásate a Pro Plus para añadir más!';
  }

  @override
  String get quickRepliesQuickRepliesSaved => 'Respuestas rápidas guardadas ⚡';

  @override
  String get quickRepliesChatQuickReplies => 'Respuestas rápidas de chat';

  @override
  String get quickRepliesTapAnyShortcutInsideChat =>
      'Toca cualquier atajo dentro del chat para responder en un toque.';

  @override
  String get quickRepliesAddQuickReply => 'Añadir respuesta rápida';

  @override
  String get quickRepliesLabel => 'Etiqueta';

  @override
  String get quickRepliesReplyText => 'Texto de respuesta...';

  @override
  String get quickRepliesAutoGreetingMessage =>
      'Mensaje de bienvenida automático';

  @override
  String get quickRepliesWelcomeStore => '¡Bienvenido a nuestra tienda!';

  @override
  String get quickRepliesSaveQuickReplies => 'Guardar respuestas rápidas';

  @override
  String get quickRepliesManage => 'Gestionar';

  @override
  String get realMarketplaceMapApproximateMapArea =>
      'Zona aproximada en el mapa';

  @override
  String realMarketplaceMapDistkmKmFromYou(Object distKm) {
    return 'A $distKm km de ti';
  }

  @override
  String get realMarketplaceMapSetAsMyZone => 'Fijar como mi zona';

  @override
  String get badgesKitBronze => 'Bronce';

  @override
  String get badgesKitSilver => 'Plata';

  @override
  String get badgesKitGold => 'Oro';

  @override
  String get badgesKitPlatinum => 'Platino';

  @override
  String get badgesKitDiamond => 'Diamante';

  @override
  String get badgesKitChampion => 'Campeón';

  @override
  String get badgesKitStarterMemberApolo => 'Miembro inicial en Apolo';

  @override
  String get badgesKitVerifiedAccount2Listings =>
      'Cuenta verificada o 2+ anuncios';

  @override
  String get badgesKitBusinessStore5Listings => 'Tienda Business o 5+ anuncios';

  @override
  String get badgesKitActiveProActiveStore8 =>
      'Pro+ activo o tienda activa (8+)';

  @override
  String get badgesKitPro10Listings1500 =>
      'Pro+ con 10+ anuncios o 1.500 visitas';

  @override
  String get badgesKitTopTierPro20Listings =>
      'Nivel máximo: Pro+ con 20+ anuncios o 5.000 visitas';

  @override
  String get badgesKitSellerRank => 'Rango de vendedor:';

  @override
  String get badgesKitTopRankUnlockedApolo =>
      '¡Máximo rango desbloqueado en Apolo!';

  @override
  String get badgesKitNext => 'Siguiente:';

  @override
  String get badgesKitTrustSellerRanks => 'Confianza y rangos de vendedor';

  @override
  String get badgesKitCurrentRank => 'Rango actual:';

  @override
  String get badgesKitVerifiedApoloAccount => 'Cuenta de Apolo verificada';

  @override
  String get badgesKitVerifiedSeal => 'Sello de Verificado';

  @override
  String get badgesKitIdentityContactDetailsVerifiedSafer =>
      'Identidad y datos de contacto verificados para tratos más seguros.';

  @override
  String get badgesKitEarnedByVerifyingPhoneNumber =>
      'Se consigue verificando tu número de teléfono o activando una tienda Pro.';

  @override
  String get badgesKitAllSellerRanks => 'Todos los rangos de vendedor';

  @override
  String get badgesKitCurrent => 'Actual';

  @override
  String get infeedUpgradeCardYourProfile => 'tu_perfil';

  @override
  String get infeedUpgradeCardBuildCredibilityBuyersWhenYou =>
      'Gana credibilidad ante los compradores al suscribirte a Apolo Premium.';

  @override
  String get infeedUpgradeCardUpgradeProfile => 'Mejora tu perfil';

  @override
  String get infeedUpgradeCardNotNow => 'Ahora no';

  @override
  String get searchSuggestionsSearchUsernames => 'Buscar nombres de usuario';

  @override
  String get searchSuggestionsSuggestions => 'Sugerencias';

  @override
  String get searchSuggestionsRecentSearches => 'Búsquedas recientes';

  @override
  String get searchSuggestionsPopularSearches => 'Búsquedas populares';

  @override
  String get followedButton => 'Seguido';

  @override
  String get writeReviewExcellent => 'Excelente';

  @override
  String get writeReviewVeryGood => 'Muy bueno';

  @override
  String get writeReviewPoor => 'Malo';

  @override
  String get writeReviewGreatCommunication => 'Buena comunicación';

  @override
  String get writeReviewAsDescribed => 'Como se describía';

  @override
  String get writeReviewFastResponse => 'Respuesta rápida';

  @override
  String get writeReviewFairPrice => 'Precio justo';

  @override
  String get writeReviewReviewHasBeenPosted => 'Tu reseña se ha publicado';

  @override
  String get writeReviewShareExperienceThisSeller =>
      'Comparte tu experiencia con este vendedor...';

  @override
  String get writeReviewUpdateReview => 'Actualizar reseña';

  @override
  String get writeReviewSubmitReview => 'Publicar reseña';

  @override
  String get interestsSurveyWhatAreInterests => '¿Qué te interesa?';

  @override
  String get interestsSurveyDiscoverProducts => 'Descubre artículos';

  @override
  String interestsSurveySaveContinueSelectedcategoryids(
      Object selectedCategoryIds) {
    return 'Guardar y continuar ($selectedCategoryIds)';
  }

  @override
  String get interestsSurveySkipNow => 'Omitir por ahora';

  @override
  String get priceLabel => 'Precio';

  @override
  String get conditionLabel => 'Estado';

  @override
  String get conditionNew => 'Nuevo';

  @override
  String get conditionLikeNew => 'Como nuevo';

  @override
  String get conditionUsed => 'De segunda mano';

  @override
  String get fulfillmentMeetInPerson => 'Entrega en mano';

  @override
  String get fulfillmentDelivery => 'Envío';

  @override
  String get listingStatusSold => 'Vendido';

  @override
  String get listingStatusReserved => 'Reservado';

  @override
  String get safetyTipsTitle => 'Consejos de seguridad';

  @override
  String get adDetailTranslate => 'Traducir';

  @override
  String get adDetailTranslating => 'Traduciendo...';

  @override
  String adDetailTranslatedFrom(Object language) {
    return 'Traducido del $language';
  }

  @override
  String get adDetailOriginalVersion => 'Original';

  @override
  String get adDetailTranslationFailed =>
      'No se pudo traducir el anuncio ahora';

  @override
  String get langNameEnglish => 'inglés';

  @override
  String get langNameFrench => 'francés';

  @override
  String get langNameArabic => 'árabe';

  @override
  String get langNameSpanish => 'español';

  @override
  String get langNameGerman => 'alemán';

  @override
  String get langNameJapanese => 'japonés';
}
