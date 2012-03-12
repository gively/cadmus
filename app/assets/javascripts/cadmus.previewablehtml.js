(function($) {
	$.fn.cadmusPreviewableHtml = function() {
		this.each(function() {
			var textarea = this;
			var $this = $(this);
			var $previewIn = $("#" + $this.attr('data-preview-in'));
			
			$this.on('cadmus.htmlChange', function(){
				$previewIn.html($this.val());
			});
			
			textarea.cadmusTextValue = "";
			setInterval(function() {
			  var newCadmusTextValue = $this.val();
			  if (textarea.cadmusTextValue != newCadmusTextValue) {
				textarea.cadmusTextValue = newCadmusTextValue;
				$this.trigger('cadmus.htmlChange');
			  }
			}, 100);
		});
	};
})(jQuery);