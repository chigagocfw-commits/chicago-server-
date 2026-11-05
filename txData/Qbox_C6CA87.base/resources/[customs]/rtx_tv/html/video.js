var videohandler = undefined

window.addEventListener("load", (event) => {
	let tvresourcenamedata = location.host;
	let tvresourcenamedata2 = tvresourcenamedata.substring(8);
	$.post('https://'+tvresourcenamedata2+'/readyyt', JSON.stringify({}));
});

// Fix #14: refactored helper — avoids duplicating the entire YT.Player constructor
// Fix #2: uses window.location.origin (scheme+host only) instead of window.location.href
function createYTPlayer(videoId, startSeconds, volume) {
	return new YT.Player("videoframe", {
		startSeconds: startSeconds,
		videoId: videoId,
		origin: window.location.origin,
		enablejsapi: 1,
		width: "0",
		height: "0",
		playerVars: {
			playsinline: 1,
			controls: 0,
		},
		events: {
			'onReady': function(event) {
				event.target.unMute();
				event.target.setVolume(volume);
				event.target.seekTo(startSeconds);
				event.target.playVideo();
			},
			'onError': function(event) {
			},
			'onStateChange': function(event) {
				if (event.data == YT.PlayerState.PLAYING) {
				}
			}
		}
	});
}

window.addEventListener('message', function (event) {

	var item = event.data;

	if (item.message == "playvideo") {
		if (videohandler != undefined) {
			videohandler.stopVideo();
			videohandler.destroy();
			videohandler = undefined;
		}
		videohandler = createYTPlayer(item.videoid, item.videoseconds, item.videovolume);
	}

	if (item.message == "updatevolume") {
		if (videohandler != undefined) {
			videohandler.setVolume(item.videovolume);
		}
	}

	if (item.message == "stopvideo") {
		if (videohandler != undefined) {
			videohandler.stopVideo();
			videohandler.destroy();
			videohandler = undefined;
		}
	}
});
