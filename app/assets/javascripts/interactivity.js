$(document).ready(function(){
  $('.new-form').hide();

  $('.reveal-form').on('click',function(){
    $('.new-form').slideToggle();
  });

  $('#queryInput').on('change',function(){
    this.form.submit();
  });

  $('#new_game').bind('ajax:success',function(event,xhr,status){
    $('#new_game')[0].reset();
  });

});
