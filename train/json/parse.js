$(document).ready(function () {
	table = train_table();
	html = table.make_html();
	$('body').append(html);
	$('div#json').hide();
});