$(document).ready(function(){
  $('.new-form').hide();

  $('.reveal-form').on('click',function(){
    $('.new-form').slideToggle();
  });

  $('#queryInput').on('change',function(){
    this.form.submit();
  });

});
