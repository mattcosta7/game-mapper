// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require foundation
//= require_tree .

$(function(){

  $(document).foundation();

  $('#dp1').fdatepicker({
    initialDate: new Date(),
    format: 'mm-dd-yyyy  hh:ii',
    disableDblClickSelection: false,
    pickTime: true
  }).on('changeDate', function (event) {
    event.preventDefault();
    var date = new Date($('#dp1').val());
    $('#real_date').val(date);
  });

});
