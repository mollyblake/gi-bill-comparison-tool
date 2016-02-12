///////////////////////////////////////////////////////////////////////////////
// autoSubmitEnable
///////////////////////////////////////////////////////////////////////////////
function autoSubmitEnable(formId, controlSel) {
	$(controlSel).each(function(idx, control) {
		$(control).change(function() {
			$(formId).submit();
		});
	});
}

$(document).ready(function() {
	autoSubmitEnable('#filter-form', '#institutions_search .filter');
});

