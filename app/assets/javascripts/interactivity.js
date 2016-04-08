$(document).ready(function(){

  $('#game_detail').hide();
  $('#queryInput').on('change',function(){
    this.form.submit();
  });

  $('#new_game').bind('ajax:success',function(event,xhr,status){
    $('#new_game')[0].reset();
  });


  $(document).on('click','.view_game', function(){
    var that = this;
    $.ajax({
      url: '/games/'+$(that).attr('api-endpoint')+'.html',
      method: 'get',
      success:function(data){
        $('#mainsection').toggle("slide", {direction: 'up'},1000);
        setTimeout(function(){
          $('#game_detail').html(data).fadeIn(500);
          if(typeof(chatChannel) != "undefined"){
            chatChannel.leave().then(function(){
              startChannel($(that).parent('div').find('.iw_sport_name').text() + "_"+ $(that).attr('api-endpoint'));
            });
          }
          else{
            startChannel($(that).parent('div').find('.iw_sport_name').text() + "_"+ $(that).attr('api-endpoint'));
          }
          $('.games_attendees_display').ready(function(){
            $('.name-text').hide();
            $('.games_attendees_display').on('mouseenter',function(){
              $(this).find('.name-text').stop(true,true).toggle('slide',{direction: 'down'}, 1000);
            }).on('mouseleave',function(){
              $(this).find('.name-text').stop(true,true).toggle('slide',{direction: 'down'}, 1000);
            });
          });
        },1000);

      }
    });

  });

  $(document).on('click','#back',function(){
    $('.games_attendees_display').off('mouseenter','*');
    $('.games_attendees_display').off('mouseleave','*');
    $('#game_detail').off('click', '*');
    $('#game_detail').html('').fadeOut(500);
    setTimeout(function(){
      $('#mainsection').toggle("slide", {direction: 'up'},1000);
    },500);
  });
});
