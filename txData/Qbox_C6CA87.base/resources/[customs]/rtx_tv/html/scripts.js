var volumeslider = document.getElementById("volumesliderdata");

var televisionresourcename = "rtx_tv";

// Fix #7: track menu state properly instead of relying on window.open (always truthy)
var menuOpen = false;

function closeMain() {
	$("body").css("display", "none");
	menuOpen = false;
}

function openMain() {
	$("body").css("display", "block");
	menuOpen = true;
}

// Fix #7: single ESC listener defined once, outside the message handler
document.addEventListener('keyup', function(data) {
	if (menuOpen && data.which == 27) {
		$.post('https://'+televisionresourcename+'/quit', JSON.stringify({}));
	}
});

$(".closetvmenu").click(function(){
	$.post('https://'+televisionresourcename+'/quit', JSON.stringify({}));
});

$(".closetvcreatorfinish").click(function(){
	$.post('https://'+televisionresourcename+'/quit', JSON.stringify({}));
});

window.addEventListener('message', function (event) {

	var item = event.data;

	if (item.message == "tvshow") {
		$("#videoinputtvdata").val(""); 
		document.getElementsByClassName("currentlytexttype")[0].textContent = item.tvurltypedata;
		volumeslider.value = item.tvvolumedata;		
		if (item.tvurldata == "") {	
			document.getElementsByClassName("currentlytextdata2")[0].textContent = "";
			document.getElementsByClassName("currentlytext")[0].textContent = "Currently no video is playing";
		} else {
			document.getElementsByClassName("currentlytext")[0].textContent = "Currently playing";
			document.getElementsByClassName("currentlytextdata2")[0].textContent = item.tvurldata;
			$("#currentlytextdatashow").show();	
		}		
		$("#vehicletvcreatorshow").hide();
		$("#vehicletvcreatorfinishshow").hide();
		$("#tvshow").show();	
		openMain();
	}	

	if (item.message == "vehicletvcreatorshow") {
		$("#tvshow").hide();
		$("#vehicletvcreatorfinishshow").hide();
		$("#vehicletvcreatorshow").show();	
		openMain();
	}	
	
	if (item.message == "vehicletvcreatorfinishshow") {
		var offsetdatatv = 
		'\t{\n' +
		'\t\tvehiclebone = "windscreen",\n' +
		'\t\toffsetx = ' + item.offsetxdata + ',\n' +
		'\t\toffsety = ' + item.offsetydata + ',\n' +
		'\t\toffsetz = ' + item.offsetzdata + ',\n' +
		'\t\trotation = ' + item.offsetrotationdata + ',\n' +
		'\t},';
		$(".tvcopytextdata").val(offsetdatatv); 
		$("#tvshow").hide();
		$("#vehicletvcreatorshow").hide();
		$("#vehicletvcreatorfinishshow").show();	
		openMain();
	}		
	
	if (item.message == "changespeed") {
		document.getElementById("currentspeeddata").textContent = item.speeddata;
	}		
	
	if (item.message == "changemode") {
		document.getElementById("currentmodedata").textContent = item.modedata;
	}		
		
	if (item.message == "hide") {
		closeMain();
	}
	
	if (item.message == "updateinterfacedata") {
		televisionresourcename = item.televisionresouredata;
		let root = document.documentElement;
		root.style.setProperty('--color', item.interfacecolordata);	
	}		
});

$(".buttonplay").click(function () {
	$.post('https://'+televisionresourcename+'/playvideo', JSON.stringify({
		videourldata: $("#videoinputtvdata").val().trim()
	}));
});

$(".buttonturnoff").click(function () {
	$.post('https://'+televisionresourcename+'/turnoff', JSON.stringify({}));
});

function volumechange(e) {
	$.post('https://'+televisionresourcename+'/volumechange', JSON.stringify({
		volumedata: e.value
	})); 
}
