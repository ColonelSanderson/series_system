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


    var dateBounds = function(date, startDate, endDate) {
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


    var sortStart = function(start) {
	return start.replace(/-/g, '').padEnd(8, '0');
    };


    var sortEnd = function(end) {
	return end.replace(/-/g, '').padEnd(8, '9');
    };


    var calculateCommonDates = function(linker, init) {
	var $linker = $(linker);

	if (!init && !$linker.closest('.subrecord-form-container').find('.token-input-token:first').is('[id]')) {
	    // linker is empty, so set placeholder and get out
	    var $common = $linker.closest('.subrecord-form-container').find('.series-system-relationship-common-dates');
	    $common.html($common.data('placeholder'));
	    return;
	}

	obj = $linker.data('selected');
	if (!obj || jQuery.isEmptyObject(obj)) {
	    obj = $linker.closest('.linker-wrapper').find('input[name$="[_resolved]"]').val();
	    if (!obj) {
		// linker is empty, so set placeholder and get out
		var $common = $linker.closest('.subrecord-form-container').find('.series-system-relationship-common-dates');
		$common.html($common.data('placeholder'));
		return;
	    }
	}

	if (typeof obj === 'string') {
	    obj = JSON.parse(obj);
	    if (obj.hasOwnProperty('json')) {
		obj = JSON.parse(obj['json']);
	    }
	}

	var linkedStart = false;
	var linkedEnd = false;

	if (obj.hasOwnProperty('date')) {
	    var newDates = dateBounds(obj['date'], linkedStart, linkedEnd);
	    linkedStart = newDates[0];
	    linkedEnd = newDates[1];
	}

	if (obj.hasOwnProperty('dates_of_existence')) {
	    $(obj['dates_of_existence']).each(function() {
		var newDates = dateBounds(this, linkedStart, linkedEnd);
		linkedStart = newDates[0];
		linkedEnd = newDates[1];
	    });
	}

	var $datesSection = $('section[id$=_dates_of_existence]');
	if ($datesSection.length == 0) {
	    $datesSection = $('section[id$=_date_]');
	}
	if ($datesSection.length == 0) {
	    $datesSection = $('section[id$=_dates_]');
	}

	var thisStart = false;
	var thisEnd = false;

	$datesSection.find('input[id$=_begin_]').each(function() {
	    if (!thisStart || $(this).val() < thisStart) {
		thisStart = $(this).val();
	    }
	});

	$datesSection.find('input[id$=_end_]').each(function() {
	    if (!thisEnd || $(this).val() > thisEnd) {
		thisEnd = $(this).val();
	    }
	});

	var commonStart = linkedStart;
	var commonEnd = linkedEnd;

	if (!linkedStart || (thisStart && sortStart(thisStart) > sortStart(linkedStart))) {
	    commonStart = thisStart;
	}

	if (!linkedEnd || (thisEnd && sortEnd(thisEnd) < sortEnd(linkedEnd))) {
	    commonEnd = thisEnd;
	}

	var msg = '';
	if (commonStart && commonEnd && sortStart(commonStart) > sortEnd(commonEnd)) {
	    msg = '-- no common dates --';
	} else {
	    if (commonStart) {
		msg += commonStart + ' -- ';
	    } else {
		msg += 'up to ';
	    }
	    if (commonEnd) {
		msg += commonEnd;
	    } else {
		msg += 'present';
	    }
	}

	var $container = $linker.closest('.subrecord-form-container');
	var $commonInput = $container.find('.series-system-relationship-common-dates');
	$commonInput.html(msg);
	$commonInput.data('start', commonStart);;
	$commonInput.data('end', commonEnd);;
    };


    var prePopulateDateFields = function(linker) {
	var $linker = $(linker);

	var $container = $linker.closest('.subrecord-form-container');
	var $commonInput = $container.find('.series-system-relationship-common-dates');
	var commonStart = $commonInput.data('start');
	var commonEnd = $commonInput.data('end');

	if (commonStart && commonEnd && sortStart(commonStart) > sortEnd(commonEnd)) {
	    return;
	}

	var $typeInput = $container.closest('li').find('input[id$=_jsonmodel_type_]:first');
	var isSuccession = $typeInput.length > 0 ? ($typeInput.val().endsWith('succession_relationship')) :
	                   $container.closest('li').find('select[name=series_system_relationship_type]').val().endsWith('succession_relationship');

	var $startInput = $container.find('input[id$=_start_date_]');
	if ($startInput.val() == '' && isSuccession ? commonEnd : commonStart) {
	    $startInput.attr('value', isSuccession ? commonEnd : commonStart);
	    $startInput.trigger('change');
	}

	if (!isSuccession) {
	    var $endInput = $container.find('input[id$=_end_date_]');
	    if ($endInput.val() == '' && commonEnd) {
		$endInput.attr('value', commonEnd);
		$endInput.trigger('change');
	    }
	}
    };


    $(document).on('change', 'section[id^=series_system_] input[id$=_date_]', function() {
	var $this = $(this);
	var $common = $this.closest('.subrecord-form-container').find('.series-system-relationship-common-dates');

	if ($this.val() != '' &&
	    (($common.data('start') && sortStart($common.data('start')) > sortStart($this.val())) ||
	     ($common.data('end') && sortEnd($common.data('end')) < sortEnd($this.val())))) {
	    $this.closest('.form-group').addClass('has-warning');
	} else {
	    $this.closest('.form-group').removeClass('has-warning');
	}
    });


    $(document).on('change', 'section[id^=series_system_] input.linker', function () {
	calculateCommonDates(this);
	prePopulateDateFields(this);
    });


    $(document).on('subrecordcreated.aspace', function (event, type, subform) {
        if (type.startsWith('series_system_')) {
	    calculateCommonDates($(subform).find('input.linker.initialised'), true);
	}
    });


     $(document).on('loadedrecordform.aspace', function () {
         $('section[id^=series_system_] input.linker.initialised').each(function() {
 	    calculateCommonDates(this, true);
 	});
     });


    $(document).on('change', 'section[id$=_dates_of_existence] input[id$=_begin_]', function () {
        $('section[id^=series_system_] input.linker.initialised').each(function() {
	    calculateCommonDates(this);
	});
    });


    $(document).on('change', 'section[id$=_dates_of_existence] input[id$=_end_]', function () {
        $('section[id^=series_system_] input.linker.initialised').each(function() {
	    calculateCommonDates(this);
	});
    });


    $(document).on('change', 'section[id$=_date_] input[id$=_begin_]', function () {
        $('section[id^=series_system_] input.linker.initialised').each(function() {
	    calculateCommonDates(this);
	});
    });


    $(document).on('change', 'section[id$=_date_] input[id$=_end_]', function () {
        $('section[id^=series_system_] input.linker.initialised').each(function() {
	    calculateCommonDates(this);
	});
    });
});
