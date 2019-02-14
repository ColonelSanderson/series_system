$(document).on("loadedrecordform.aspace", function(event) {
    $('#resource_id_0_').attr('type', 'hidden');
    $('#resource_id_0_').closest('div').append('<div class="col-sm-9 label-only">' + $('#resource_id_0_').attr('value') + '</div>');

    $('#resource_id_1_').hide();
    $('#resource_id_2_').hide();
    $('#resource_id_3_').hide();
});
