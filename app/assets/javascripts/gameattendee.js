$(document).ready(function(){

  $(document).on('click','.join_link',function(e){
    $.ajax({
      url: $(e.target).attr('href'),
      method: $(e.target).attr('data-method'),
      success: function(data){
        var content;
        if($(e.target).text() == "Leave Game"){
          content="<button class='join_link button success' href='"+$(e.target).attr('href')+"' data-method='post'>Join Game</button>";
        }
        else{
          content="<button class='join_link button alert' href='"+$(e.target).attr('href')+"' data-method='delete'>Leave Game</button>";
        }
        $(e.target).replaceWith(content);
        $('#map .join_link').replaceWith(content);
      }

    });
  });

});
