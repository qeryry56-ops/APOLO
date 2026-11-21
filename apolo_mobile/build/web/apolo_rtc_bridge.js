/**
 * Apolo Media & WebRTC Bridge (Voice Notes + Peer-to-Peer Audio/Video Calls)
 * Zero external dependencies — works natively on modern mobile & desktop browsers.
 */
(function () {
  // ========================= 1. VOICE NOTES =========================
  let _mediaRecorder = null;
  let _audioChunks = [];
  let _micStream = null;
  let _recordStartMs = 0;
  let _activeAudio = null;
  let _activeAudioId = null;
  let _progressInterval = null;

  function pickAudioMime() {
    if (typeof MediaRecorder === 'undefined') return '';
    const candidates = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/mp4',
      'audio/ogg;codecs=opus'
    ];
    for (const mime of candidates) {
      if (MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported(mime)) {
        return mime;
      }
    }
    return '';
  }

  function stopMicStream() {
    if (_micStream) {
      _micStream.getTracks().forEach((t) => {
        try { t.stop(); } catch (_) {}
      });
      _micStream = null;
    }
  }

  window.ApoloVoice = {
    isSupported: function () {
      return !!(
        navigator &&
        navigator.mediaDevices &&
        navigator.mediaDevices.getUserMedia &&
        typeof MediaRecorder !== 'undefined'
      );
    },

    startRecording: async function () {
      try {
        window.ApoloVoice.pause();
        stopMicStream();
        _audioChunks = [];
        _micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const mime = pickAudioMime();
        const opts = mime ? { mimeType: mime, audioBitsPerSecond: 24000 } : { audioBitsPerSecond: 24000 };
        _mediaRecorder = new MediaRecorder(_micStream, opts);
        _mediaRecorder.ondataavailable = function (e) {
          if (e.data && e.data.size > 0) _audioChunks.push(e.data);
        };
        _recordStartMs = Date.now();
        _mediaRecorder.start(200);
        return true;
      } catch (e) {
        stopMicStream();
        return false;
      }
    },

    stopRecording: function () {
      return new Promise((resolve) => {
        if (!_mediaRecorder || _mediaRecorder.state === 'inactive') {
          stopMicStream();
          resolve('');
          return;
        }
        const durationSec = Math.max(1, Math.round((Date.now() - _recordStartMs) / 1000));
        const mime = _mediaRecorder.mimeType || 'audio/webm';
        _mediaRecorder.onstop = function () {
          stopMicStream();
          const blob = new Blob(_audioChunks, { type: mime });
          _audioChunks = [];
          const reader = new FileReader();
          reader.onloadend = function () {
            const dataUrl = reader.result || '';
            const idx = dataUrl.indexOf(',');
            const base64 = idx >= 0 ? dataUrl.slice(idx + 1) : '';
            resolve(JSON.stringify({ base64, mime, durationSec }));
          };
          reader.onerror = function () {
            resolve('');
          };
          reader.readAsDataURL(blob);
        };
        try {
          _mediaRecorder.stop();
        } catch (_) {
          stopMicStream();
          resolve('');
        }
      });
    },

    cancelRecording: function () {
      try {
        if (_mediaRecorder && _mediaRecorder.state !== 'inactive') {
          _mediaRecorder.onstop = null;
          _mediaRecorder.stop();
        }
      } catch (_) {}
      _mediaRecorder = null;
      _audioChunks = [];
      stopMicStream();
    },

    play: function (id, base64, mime, onProgress, onEnded) {
      window.ApoloVoice.pause();
      try {
        const src = 'data:' + (mime || 'audio/webm') + ';base64,' + base64;
        const audio = new Audio(src);
        _activeAudio = audio;
        _activeAudioId = id;

        audio.onended = function () {
          clearInterval(_progressInterval);
          _progressInterval = null;
          _activeAudio = null;
          _activeAudioId = null;
          if (onEnded) onEnded();
        };

        audio.onerror = function () {
          clearInterval(_progressInterval);
          _progressInterval = null;
          _activeAudio = null;
          _activeAudioId = null;
          if (onEnded) onEnded();
        };

        _progressInterval = setInterval(function () {
          if (!_activeAudio || _activeAudioId !== id) return;
          if (_activeAudio.duration && isFinite(_activeAudio.duration) && _activeAudio.duration > 0) {
            const p = Math.min(1, Math.max(0, _activeAudio.currentTime / _activeAudio.duration));
            if (onProgress) onProgress(p);
          }
        }, 120);

        audio.play().catch(function () {
          if (onEnded) onEnded();
        });
      } catch (_) {
        if (onEnded) onEnded();
      }
    },

    pause: function () {
      if (_progressInterval) {
        clearInterval(_progressInterval);
        _progressInterval = null;
      }
      if (_activeAudio) {
        try {
          _activeAudio.pause();
        } catch (_) {}
        _activeAudio = null;
        _activeAudioId = null;
      }
    }
  };

  // ========================= 2. WEBRTC CALLS =========================
  let _pc = null;
  let _localStream = null;
  let _remoteStream = null;
  let _remoteAudioEl = null;
  let _videoOverlay = null;
  let _pendingIce = [];

  const RTC_CONFIG = {
    iceServers: [
      { urls: ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'] }
    ]
  };

  function removeVideoOverlay() {
    if (_videoOverlay && _videoOverlay.parentNode) {
      _videoOverlay.parentNode.removeChild(_videoOverlay);
    }
    _videoOverlay = null;
    if (_remoteAudioEl && _remoteAudioEl.parentNode) {
      _remoteAudioEl.parentNode.removeChild(_remoteAudioEl);
    }
    _remoteAudioEl = null;
  }

  function mountMediaElements(isVideo) {
    removeVideoOverlay();

    if (!isVideo) {
      _remoteAudioEl = document.createElement('audio');
      _remoteAudioEl.autoplay = true;
      _remoteAudioEl.playsInline = true;
      _remoteAudioEl.style.display = 'none';
      document.body.appendChild(_remoteAudioEl);
      return;
    }

    const wrap = document.createElement('div');
    wrap.id = 'apolo-rtc-overlay';
    wrap.style.cssText =
      'position:fixed;top:64px;left:16px;right:16px;bottom:148px;z-index:9999;pointer-events:none;border-radius:24px;overflow:hidden;';

    const remoteVid = document.createElement('video');
    remoteVid.id = 'apolo-rtc-remote';
    remoteVid.autoplay = true;
    remoteVid.playsInline = true;
    remoteVid.style.cssText =
      'width:100%;height:100%;object-fit:cover;background:#111;border-radius:24px;';

    const localVid = document.createElement('video');
    localVid.id = 'apolo-rtc-local';
    localVid.autoplay = true;
    localVid.muted = true;
    localVid.playsInline = true;
    localVid.style.cssText =
      'position:absolute;top:14px;right:14px;width:104px;height:146px;object-fit:cover;border-radius:16px;border:2px solid rgba(255,255,255,0.85);background:#222;box-shadow:0 8px 24px rgba(0,0,0,0.4);';

    wrap.appendChild(remoteVid);
    wrap.appendChild(localVid);
    document.body.appendChild(wrap);
    _videoOverlay = wrap;
  }

  function createPeerConnection(isVideo, onIceCandidate, onConnectionState) {
    _pc = new RTCPeerConnection(RTC_CONFIG);
    _remoteStream = new MediaStream();
    _pendingIce = [];

    _pc.onicecandidate = function (event) {
      if (event.candidate && onIceCandidate) {
        onIceCandidate(JSON.stringify(event.candidate.toJSON()));
      }
    };

    _pc.onconnectionstatechange = function () {
      if (_pc && onConnectionState) {
        onConnectionState(_pc.connectionState || 'connecting');
      }
    };

    _pc.ontrack = function (event) {
      event.streams[0].getTracks().forEach((track) => {
        _remoteStream.addTrack(track);
      });
      if (isVideo) {
        const remoteVid = document.getElementById('apolo-rtc-remote');
        if (remoteVid) remoteVid.srcObject = _remoteStream;
      } else if (_remoteAudioEl) {
        _remoteAudioEl.srcObject = _remoteStream;
      }
    };
  }

  async function flushPendingIce() {
    if (!_pc || !_pc.remoteDescription) return;
    while (_pendingIce.length > 0) {
      const c = _pendingIce.shift();
      try {
        await _pc.addIceCandidate(new RTCIceCandidate(c));
      } catch (_) {}
    }
  }

  window.ApoloRTC = {
    isSupported: function () {
      return !!(
        typeof RTCPeerConnection !== 'undefined' &&
        navigator &&
        navigator.mediaDevices &&
        navigator.mediaDevices.getUserMedia
      );
    },

    startCaller: async function (isVideo, onIceCandidate, onConnectionState) {
      try {
        window.ApoloRTC.endCall();
        _localStream = await navigator.mediaDevices.getUserMedia({
          audio: true,
          video: isVideo ? { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } } : false
        });
        mountMediaElements(isVideo);
        if (isVideo) {
          const localVid = document.getElementById('apolo-rtc-local');
          if (localVid) localVid.srcObject = _localStream;
        }
        createPeerConnection(isVideo, onIceCandidate, onConnectionState);
        _localStream.getTracks().forEach((track) => _pc.addTrack(track, _localStream));

        const offer = await _pc.createOffer();
        await _pc.setLocalDescription(offer);
        return JSON.stringify({ type: offer.type, sdp: offer.sdp });
      } catch (e) {
        window.ApoloRTC.endCall();
        return '';
      }
    },

    applyRemoteAnswer: async function (answerJson) {
      try {
        if (!_pc || !answerJson) return;
        const ans = JSON.parse(answerJson);
        await _pc.setRemoteDescription(new RTCSessionDescription(ans));
        await flushPendingIce();
      } catch (_) {}
    },

    answerCallee: async function (offerJson, isVideo, onIceCandidate, onConnectionState) {
      try {
        window.ApoloRTC.endCall();
        _localStream = await navigator.mediaDevices.getUserMedia({
          audio: true,
          video: isVideo ? { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } } : false
        });
        mountMediaElements(isVideo);
        if (isVideo) {
          const localVid = document.getElementById('apolo-rtc-local');
          if (localVid) localVid.srcObject = _localStream;
        }
        createPeerConnection(isVideo, onIceCandidate, onConnectionState);
        _localStream.getTracks().forEach((track) => _pc.addTrack(track, _localStream));

        const offer = JSON.parse(offerJson);
        await _pc.setRemoteDescription(new RTCSessionDescription(offer));
        await flushPendingIce();

        const answer = await _pc.createAnswer();
        await _pc.setLocalDescription(answer);
        return JSON.stringify({ type: answer.type, sdp: answer.sdp });
      } catch (e) {
        window.ApoloRTC.endCall();
        return '';
      }
    },

    addIceCandidate: async function (candidateJson) {
      try {
        if (!candidateJson) return;
        const candidate = JSON.parse(candidateJson);
        if (_pc && _pc.remoteDescription) {
          await _pc.addIceCandidate(new RTCIceCandidate(candidate));
        } else {
          _pendingIce.push(candidate);
        }
      } catch (_) {}
    },

    setMuted: function (muted) {
      if (_localStream) {
        _localStream.getAudioTracks().forEach((t) => { t.enabled = !muted; });
      }
    },

    setCameraEnabled: function (enabled) {
      if (_localStream) {
        _localStream.getVideoTracks().forEach((t) => { t.enabled = !!enabled; });
      }
    },

    endCall: function () {
      _pendingIce = [];
      if (_pc) {
        try { _pc.close(); } catch (_) {}
        _pc = null;
      }
      if (_localStream) {
        _localStream.getTracks().forEach((t) => {
          try { t.stop(); } catch (_) {}
        });
        _localStream = null;
      }
      _remoteStream = null;
      removeVideoOverlay();
    }
  };
})();
