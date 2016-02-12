///////////////////////////////////////////////////////////////////////////////
// Builds a query string 
///////////////////////////////////////////////////////////////////////////////
function buildQueryStr(controlSel) {
	var qstr = "";

  $(controlSel).each(function(idx, control) {
  	if ($(control).is(':checkbox') || $(control).is(':radio')) {
  		if ($(control).is(':checked')) {
  			qstr += $(control).attr('name') + "=" 
  				+ encodeURIComponent($(control).val()) + "&";
  		}
  	}
  	else {
  		qstr += $(control).attr('name') + "=" 
  			+ encodeURIComponent($(control).val()) + "&";
  	}
  });

  return qstr;
}

function controlsToQueryString(controls) {
  var qstr = '?';
	var baseUrl = window.location.href.split("?")[0];

	for (var i = 0; i < controls.length; i++) {
		qstr += buildQueryStr(controls[i])
	}

	return baseUrl + qstr;
}
