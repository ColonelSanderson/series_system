$(function() {

    var initSeriesSystemRelationshipForm = function(subform) {

        $("[name=series_system_relationship_type]", subform).change(function(event) {
            var type = $(this).val();

            var $targetContainer = $(this).parents(".form-group:first").siblings('.relationship-subform');
            var index = $(this).parents("[data-index]:first").data("index");

            var template_data = {
                path: AS.quickTemplate($(this).parents("[data-name-path]:first").data("name-path"), {index: index}),
                id_path: AS.quickTemplate($(this).parents("[data-id-path]:first").data("id-path"), {index: index}),
                index: index
            };

            var $related_function_type_subform = $(AS.renderTemplate("template_"+type, template_data));

            $targetContainer.html($related_function_type_subform);

            $(document).triggerHandler("subrecordcreated.aspace", ["series_system_relationship_type", $related_function_type_subform]);
        });

    };

    $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
        if (object_name === "series_system_relationship") {
            initSeriesSystemRelationshipForm($(subform));
        }
    });

    $(document).on('change', 'section[id^=series_system_] input.linker', function () {
	    console.log('weeeeeeeeeee');
    });

    dateBounds = function(date, startDate, endDate) {
	if (date['label'] == 'existence') {
	    if (date.hasOwnProperty('begin')) {
		if (!startDate || startDate > date['begin']) {
		    startDate = date['begin'];
		}
	    }
	    if (date.hasOwnProperty('end')) {
		if (!endDate || endDate < date['end']) {
		    endDate = date['end'];
		}
	    }
	}
	return [startDate, endDate];
    };


    $(document).on('loadedrecordform.aspace', function () {
        $('section[id^=series_system_] input.linker.initialised').each(function() {
		$linker = $(this);
		obj = $linker.data('selected');

		var startDate = false;
		var endDate = false;

		if (obj.hasOwnProperty('date')) {
		    newDates = dateBounds(obj['date'], startDate, endDate);
		    startDate = newDates[0];
		    endDate = newDates[1];
		}

		if (obj.hasOwnProperty('dates_of_existence')) {
		    $(obj['dates_of_existence']).each(function() {
			    newDates = dateBounds(this, startDate, endDate);
			    startDate = newDates[0];
			    endDate = newDates[1];
			});
		}

		console.log('start:  ' + startDate);
		console.log('end:    ' + endDate);

		$datesSection = $('section[id$=_dates_of_existence]');

		console.log($datesSection);

		var myStartDate = false;
		var myEndDate = false;

		$datesSection.find('input[id$=_begin_]').each(function() {
			if (!myStartDate || $(this).val() < myStartDate) {
			    myStartDate = $(this).val();
			}
		    });

		$datesSection.find('input[id$=_end_]').each(function() {
			if (!myEndDate || $(this).val() > myEndDate) {
			    myEndDate = $(this).val();
			}
		    });

		console.log('my start:  ' + myStartDate);
		console.log('my end:    ' + myEndDate);

		if (!startDate || (myStartDate && myStartDate.padEnd(10, '0') > startDate.padEnd(10, '0'))) {
		    startDate = myStartDate;
		}

		if (!endDate || (myEndDate && myEndDate.padEnd(10, '9') < endDate.padEnd(10, '9'))) {
		    endDate = myEndDate;
		}

		var label = '<label class="control-label col-sm-2">Common dates</label>';
		var msg = '';
		if (startDate) {
		    msg += startDate + ' -- ';
		} else {
		    msg += 'up to ';
		}
		if (endDate) {
		    msg += endDate;
		} else {
		    msg += 'present';
		}
		msg = '<div class="col-sm-9"><div class="label-only">' + msg + '</div></div>';

		$('<div class="form-group">' + label + msg + '</div>').insertAfter($linker.parents('.form-group:first'));

	});
    });
});
