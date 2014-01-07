$(document).ready(function () {
	tables = train_tables();
	html = make_html(tables);
	$('body').append(html);
	$('div.json').hide();
});