var ReportsTable = function (headings, reports_element) {
	var that = this;
	this.reports = get_reports(reports_element);
	this.label = get_label(reports_element);
	this.headings = headings;
	

	this.make_html = function () {
		var title_html = make_title_html();
		var header_html = make_header_html();
		var table_rows = make_rows_html();
		var html = "<table border>" + title_html + header_html + table_rows + "</table>";
		return html;
	};

	function make_title_html() {
		var html = "<caption>" + that.label + "</caption>";
		return html;
	}

	function make_header_html() {
		row = "<tr>";
		for (i = 0; i < that.headings.length; i++) {
			cell = "<th>" + that.headings[i] + "</th>";
			row += cell;
		}

		row += "</tr>";

		return row;
	}

	function get_reports(reports_element) {
		json = reports_element.innerHTML;
		reports = JSON.parse(json);
		return reports;
	};

	function get_label(reports_element) {
		var label = $(reports_element).attr('id');
		return label;
	}

	function make_rows_html () {
		var rows = [];

		for (i = 0; i < that.reports.length; i++) {
			report = that.reports[i];
			row = make_row_html_from_report(report);
			rows.push(row);
		};
 
	  return rows;
	}

	 function make_row_html_from_report (report) {
		var row = "<tr>";

		for (j = 0; j < that.headings.length; j++) {
			key = that.headings[j];
			var cell = "<td>" + report[key] + "</td>";
			row += cell;
		};

		row += "</tr>";

		return row;
	}
}


var Document = function (headings) {
	var that = this;
	this.reports = get_reports();
	this.headings = headings;
	this.tables = make_tables();
	this.html = make_html();

	this.get_html = function () {
		return that.html.join('');
	}

	function get_reports () {
		return $('div.json');
	}

	function make_tables () {
		var tables = [];
		for (g = 0; g < that.reports.length; g++) {
			table = make_table(that.reports[g])
			tables.push(table);
		};
		return tables;
	}

	function make_table(report) {
		return new ReportsTable(that.headings, report);
	}

	function make_html () {
		var html = [];

		for (h = 0; h < that.tables.length; h++) {
			table_html = that.tables[h].make_html();
			html.push(table_html);
		};
		return html;
	}

}

function bus_tables () {
	headings = ['timestamp', 'stop_id', 'stop_name', 'route', 'route_dir', 'predicted_time', 'feet_left_to_stop', 'delayed', 'vehicle_id'];
	tables = new Document(headings);
	return tables;
}

function train_tables () {
	headings = ['timestamp', 'station_id', 'stop_id', 'station_name', 'platform_name',
	 'run_number', 'route_name', 'destination_stpd_id', 'destination_name',
	 'direction_code', 'arrival_time', 'is_approaching',
	 'is_scheduled_prediction', 'fault_detected', 'delay_detected', 'latitude', 'longitude'];
	tables = new Document(headings);
	return tables;
}

function comp_tables() {
	headings = ['stop_id', 'id', 'times']
	tables = new Document(headings);
	return tables;
}
