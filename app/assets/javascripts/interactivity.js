$(document).ready(function(){

  $('.form-div').hide();
  $('#game_detail').hide();
  $('#queryInput').on('change',function(){
    this.form.submit();
  });

  $('#new_game').bind('ajax:success',function(event,xhr,status){
    $('#new_game')[0].reset();
  });

  $('button').on('click',function(){
    $('.form-div').toggle("slide", { direction: "right" }, 1000);
  })

  $(document).on('click','.view_game', function(){
    var that = this;
    $.ajax({
      url: '/games/'+$(that).attr('api-endpoint')+'.html',
      method: 'get',
      success:function(data){
        $('#game_detail').html(data).toggle("slide", {direction: 'down'},1000);
        $('#map').toggle("slide", {direction: 'up'},1000);
      }
    })

  })

  $(document).on('click','#back',function(){
    $('#game_detail').html('').toggle("slide", {direction: 'down'},1000);
    $('#map').toggle("slide", {direction: 'up'},1000);
    
  })
});
