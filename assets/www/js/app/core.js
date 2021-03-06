/*
 * The main script for Thyrd, after all libraries
 * have been loaded and the DOM is ready.
 */
define([
	'js/app/space/space.js',
    'plugins/domReady'
], function(ThyrdSpace, domReady) {
    domReady(function() {

        // Create the space

        ThyrdSpace.exist(function() {
            Thyrd.space.save(function() {
                alert('saved, root is ' + Thyrd.space.root);
            });
        });

        // Create the UI
        
        var content, columns, compiledCardTemplate = undefined;
        var MIN_COL_WIDTH = 300;
        
        //data used to render the HTML templates
        var cards_data = [
            {   title:"This is a card!", 
                message:"In essence, a card is just a rectangular region which contains content. This content is just HTML.  This could be <b>text</b>, <i>images</i>, <u>lists</u>, etc... The card UI metaphor dictates the interaction and layout of these regions."  },
            {   message:"Yep, just some simple content ecapsulated in this card.",
                image:"image1"},
            {   image:"image2",
                banner:true, 
                caption:"Image, Banner &amp; HTML",
                message:"All standard HTML structures, styled with CSS."},
            {   title:"This is another card!", 
                image:"image4",
                message:"Here, you can see a more complex card.  IT is all just layout of HTML structures.",
                caption:"Look, it's Vegas!",  },
            {   message:"Yep, just some simple content ecapsulated in this card.",
                image:"image5",
                banner:true, },
            {   image:"image6",
                caption:"An image",
                message:"With HTML in the content.<ul><li>Bullet 1</li><li>Bullet 2</li><li>Bullet 3</li></ul>"},
            {   image:"image1",
                caption:"Another image",
                message:"All of these photos were captured with a quadcopter and GoPro!"},
        ];
          
        //resize event handler
        function onResize() {
            var targetColumns = Math.floor( $(document).width()/MIN_COL_WIDTH );
            if ( columns != targetColumns ) {
                layoutColumns();   
            }
        }
        
        //function to layout the columns
        function layoutColumns() {
            content.detach();
            content.empty();
            
            columns = Math.floor( $(document).width()/MIN_COL_WIDTH );
            
            var columns_dom = [];
            for ( var x = 0; x < columns; x++ ) {
                var col = $('<div class="column">');
                col.css( "width", Math.floor(100/columns)+"%" );
                columns_dom.push( col );   
                content.append(col);
            }
            
            for ( var x = 0; x < cards_data.length; x++ ) {
                var html = compiledCardTemplate( cards_data[x] );
                
                var targetColumn = x % columns_dom.length;
                columns_dom[targetColumn].append( $(html) );    
            }
            $("body").prepend (content);
        }
            
        var content = $(".content");
        var compiledCardTemplate = Mustache.compile( $("#card-template").html() );
        layoutColumns();
        $(window).resize(onResize);
    });
});
