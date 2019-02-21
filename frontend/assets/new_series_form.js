$(document).ready(function() {
    $('#resource_id_0_').attr('type', 'hidden');
    $('#resource_id_0_').attr('disabled', 'disabled');
    $('#resource_id_0_').removeAttr('value');
    $('#resource_id_0_').closest('div').append('<div class="col-sm-9 label-only"><em>-- auto-generated on save --</em></div>');

    $('#resource_id_1_').hide();
    $('#resource_id_2_').hide();
    $('#resource_id_3_').hide();
});
