package com.codename1.demo.poker.mirah

import com.codename1.ui.Button
import com.codename1.ui.Component
import com.codename1.ui.Container
import com.codename1.ui.Dialog
import com.codename1.ui.Display
import com.codename1.ui.Form
import com.codename1.ui.Image
import com.codename1.ui.Label
import com.codename1.ui.TextArea
import com.codename1.ui.animations.CommonTransitions
import com.codename1.ui.events.ActionEvent
import com.codename1.ui.events.ActionListener
import com.codename1.ui.geom.Dimension
import com.codename1.ui.layouts.BorderLayout
import com.codename1.ui.layouts.BoxLayout
import com.codename1.ui.layouts.FlowLayout
import com.codename1.ui.layouts.GridLayout
import com.codename1.ui.layouts.LayeredLayout
import com.codename1.ui.plaf.UIManager
import com.codename1.ui.util.Resources
import com.codename1.ui.util.UITimer
import java.io.IOException
import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import java.util.List

/**
 * Demo app showing how a simple poker card game can be written using Codename One, this
 * demo was developed for an SD Journal article.
 * @author Shai Almog
 * Ported to Mirah by Steve Hannah
 */

class Poker 
    
    attr_accessor cards:Resources,
        current:Form
    
    @@SUITE_SPADE = 's'.charAt(0)
    @@SUITE_HEART = 'h'.charAt(0)
    @@SUITE_DIAMOND = 'd'.charAt(0)
    @@SUITE_CLUB = 'c'.charAt(0)
    
    def self.initialize
        
        # we initialize constant card values that will be useful later on in the game
        @@deck = Card[52]
        13.times do |iter|
            @@deck[iter] = Card.new(@@SUITE_SPADE, iter + 2)
            @@deck[iter + 13] = Card.new(@@SUITE_HEART, iter + 2)
            @@deck[iter + 26] = Card.new(@@SUITE_DIAMOND, iter + 2)
            @@deck[iter + 39] = Card.new(@@SUITE_CLUB, iter + 2)
        end
    end

    /**
     * We use this method to calculate a "fake" DPI based on screen resolution rather than its actual DPI
     * this is useful so we can have large images on a tablet
     */
    def calculateDPI
        pixels = Display.getInstance.getDisplayHeight * Display.getInstance.getDisplayWidth
        if pixels > 1000000
            Display.DENSITY_HD
        elsif pixels > 340000
            Display.DENSITY_VERY_HIGH
        elsif pixels > 150000
            Display.DENSITY_HIGH
        else
            Display.DENSITY_MEDIUM
        end
    end
    
    /**
     * This method is invoked by Codename One once when the application loads
     */
    def init(context:Object):void
        begin
            # after loading the default theme we load the card images as a resource with
            # a fake DPI so they will be large enough. We store them in a resource rather 
            # than as files so we can use the MultiImage functionality
            theme = Resources.openLayered("/theme")
            UIManager.getInstance.setThemeProps(theme.getTheme(theme.getThemeResourceNames[0]))
            @cards = Resources.open("/gamedata.res", calculateDPI())
        rescue IOException => e 
            e.printStackTrace
        end
    end
    
    /**
     * This method is invoked by Codename One once when the application loads and when it is restarted
     */
    def start:void
        if current != nil
            current.show
            return
        end
        showSplashScreen
    end
    
    /**
     * The splash screen is relatively bare bones. Its important to have a splash screen for iOS 
     * since the build process generates a screenshot of this screen to speed up perceived performance
     */
    def showSplashScreen:void
        splash = Form.new
        
        # a border layout places components in the center and the 4 sides.
        # by default it scales the center component so here we configure
        # it to place the component in the actual center
        border = BorderLayout.new
        border.setCenterBehavior(BorderLayout.CENTER_BEHAVIOR_CENTER_ABSOLUTE)
        splash.setLayout(border)
        
        # by default the form's content pane is scrollable on the Y axis
        # we need to disable it here
        splash.setScrollable(false)
        title = Label.new("Poker Ace")
        
        # The UIID is used to determine the appearance of the component in the theme
        title.setUIID("SplashTitle")
        subtitle = Label.new("By Codename One")
        subtitle.setUIID("SplashSubTitle")
        
        splash.addComponent(BorderLayout.NORTH, title)
        splash.addComponent(BorderLayout.SOUTH, subtitle)
        as = Label.new(cards.getImage("as.png"))
        ah = Label.new(cards.getImage("ah.png"))
        ac = Label.new(cards.getImage("ac.png"))
        ad = Label.new(cards.getImage("ad.png"))

        # a layered layout places components one on top of the other in the same dimension, it is
        # useful for transparency but in this case we are using it for an animation
        center = Container.new(LayeredLayout.new)
        center.addComponent(as)
        center.addComponent(ah)
        center.addComponent(ac)
        center.addComponent(ad)
        
        splash.addComponent(BorderLayout.CENTER, center)
                
        splash.show()
        splash.setTransitionOutAnimator(CommonTransitions.createCover(CommonTransitions.SLIDE_VERTICAL, true, 800))
        me=self
        # postpone the animation to the next cycle of the EDT to allow the UI to render fully once
        Display.getInstance.callSerially do
            
            # We replace the layout so the cards will be laid out in a line and animate the hierarchy
            # over 2 seconds, this effectively creates the effect of cards spreading out
            center.setLayout(BoxLayout.new(BoxLayout.X_AXIS))
            center.setShouldCalcPreferredSize(true)
            splash.getContentPane.animateHierarchy(2000)

            # after showing the animation we wait for 2.5 seconds and then show the game with a nice
            # transition, notice that we use UI timer which is invoked on the Codename One EDT thread!
            timer = UITimer.new {me.showGameUI}.schedule(2500, false, splash)
            
        end
    end

    /**
     * This is the method that shows the game running, it is invoked to start or restart the game
     */
    def showGameUI:void
        # we use the java.util classes to shuffle a new instance of the deck 
        shuffledDeck = CardList.new(Arrays.asList(deck))
        Collections.shuffle(shuffledDeck)
        
        gameForm = Form.new
        gameForm.setTransitionOutAnimator(CommonTransitions.createCover(CommonTransitions.SLIDE_VERTICAL, true, 800))
        gameFormBorderLayout = Container.new(BorderLayout.new)
        
        # while flow layout is the default in this case we want it to center into the middle of the screen
        fl = FlowLayout.new(Component.CENTER)
        fl.setValign(Component.CENTER)
        gameUpperLayer = Container.new(fl)
        gameForm.setScrollable(false)
        
        # we place two layers in the game form, one contains the contents of the game and another one on top contains instructions
        # and overlays. In this case we only use it to write a hint to the user when he needs to swap his cards
        gameForm.setLayout(LayeredLayout.new)
        gameForm.addComponent(gameFormBorderLayout)
        gameForm.addComponent(gameUpperLayer)
        
        # The game itself is comprised of 3 containers, one for each player containing a grid of 5 cards (grid layout
        # divides space evenly) and the deck of cards/dealer. Initially we show an animation where all the cards
        # gather into the deck, that is why we set the initial deck layout to show the whole deck 4x13
        deckContainer = Container.new(GridLayout.new(4, 13))
        playerContainer = Container.new(GridLayout.new(1, 5))
        rivalContainer = Container.new(GridLayout.new(1, 5))

        # we place all the card images within the deck container for the initial animation
        deck.length.times do |iter|
            face = Label.new(cards.getImage(deck[iter].getFileName))
            
            # containers have no padding or margin this effectively removes redundant spacing
            face.setUIID("Container")
            deckContainer.addComponent(face)
        end
        
        # we place our cards at the bottom, the deck at the center and our rival on the north
        gameFormBorderLayout.addComponent(BorderLayout.CENTER, deckContainer)
        gameFormBorderLayout.addComponent(BorderLayout.NORTH, rivalContainer)
        gameFormBorderLayout.addComponent(BorderLayout.SOUTH, playerContainer)
        gameForm.show()
        
        me=self
        # we wait 1.8 seconds to start the opening animation, otherwise it might start while the transition is still running
        UITimer.new do
            
            # we add a card back component and make it a drop target so later players
            # can drag their cards here
            @cardBack = Button.new(me.cards.getImage("card_back.png"))
            @cardBack.setDropTarget(true)
            
            # we remove the button styling so it doesn't look like a button by using setUIID.
            @cardBack.setUIID("Label")
            deckContainer.addComponent(cardBack)
            
            # we set the layout to layered layout which places all components one on top of the other then animate
            # the layout into place, this will cause the spread out deck to "flow" into place
            # Notice we are using the AndWait variant which will block the event dispatch thread (legally) while
            # performing the animation, normally you can't block the dispatch thread (EDT)
            deckContainer.setLayout(LayeredLayout.new)
            deckContainer.animateLayoutAndWait(3000)

            
            # we don't need all the card images/labels in the deck, so we place the card back
            # on top then remove all the other components
            deckContainer.removeAll
            deckContainer.addComponent(cardBack)
            
            # Now we iterate over the cards and deal the top card from the deck to each player
            5.times do |iter|
                @currentCard = shuffledDeck[0]
                shuffledDeck.remove(0)
                me.dealCard(@cardBack, playerContainer, me.cards.getImage(currentCard.getFileName), @currentCard)
                @currentCard = shuffledDeck[0]
                shuffledDeck.remove(0)
                me.dealCard(@cardBack, rivalContainer, me.cards.getImage("card_back.png"), @currentCard)
            end
            
            # After dealing we place a notice in the upper layer by fade in. The trick is in adding a blank component 
            # and replacing it with a fade transition
            notice = TextArea.new("Drag cards to the deck to swap\ntap the deck to finish")
            notice.setEditable(false)
            notice.setFocusable(false)
            notice.setUIID("Label")
            notice.getUnselectedStyle.setAlignment(Component.CENTER)
            gameUpperLayer.addComponent(notice)
            gameUpperLayer.layoutContainer
            
            # we place the notice then remove it without the transition, we need to do this since a text area
            # might resize itself so we need to know its size in advance to fade it in.
            temp = Label.new(" ")
            temp.setPreferredSize(Dimension.new(notice.getWidth, notice.getHeight))
            gameUpperLayer.replace(notice, temp, nil)
            
            gameUpperLayer.layoutContainer
            gameUpperLayer.replace(temp, notice, CommonTransitions.createFade(1500))
            
            # when the user taps the card back (the deck) we finish the game
            @cardBack.addActionListener do |evt|
                
                # we clear the notice text
                gameUpperLayer.removeAll
                
                # we deal the new cards to the player (the rival never takes new cards)
                while playerContainer.getComponentCount < 5
                    currentCard = shuffledDeck[0]
                    shuffledDeck.remove(0)
                    me.dealCard(Button(evt.getSource), playerContainer, me.cards.getImage(currentCard.getFileName), currentCard)
                end
                
                # expose the rivals deck then offer the chance to play again...
                5.times do |iter|
                    cardButton = Button(rivalContainer.getComponentAt(iter))
                    
                    # when creating a card we save the state into the component itself which is very convenient
                    currnetCard = Card(cardButton.getClientProperty("card"))
                    l = Label.new(me.cards.getImage(currnetCard.getFileName))
                    rivalContainer.replaceAndWait(cardButton, l, CommonTransitions.createCover(CommonTransitions.SLIDE_VERTICAL, true, 300))
                end
                
                # notice dialogs are blocking by default so its pretty easy to write this logic
                if !Dialog.show("Again?", "Ready to play Again", "Yes", "Exit") 
                    Display.getInstance.exitApplication
                end
                
                # play again
                me.showGameUI
                
            end
            
        end.schedule(1800, false, gameForm)
    end
    
    /**
     * A blocking method that creates the card deal animation and binds the drop logic when cards are dropped on the deck
     */
    def dealCard(deck:Component, destination:Container, cardImage:Image, currentCard:Card):void 
        card = Button.new
        card.setUIID("Label")
        card.setIcon(cardImage)
        
        # Components are normally placed by layout managers so setX/Y/Width/Height shouldn't be invoked. However,
        # in this case we want the layout animation to deal from a specific location. Notice that we use absoluteX/Y
        # since the default X/Y are relative to their parent container.
        card.setX(deck.getAbsoluteX)
        deckAbsY = deck.getAbsoluteY
        if destination.getY > deckAbsY 
            card.setY(deckAbsY - destination.getAbsoluteY)
        else
            card.setY(deckAbsY)
        end
        card.setWidth(deck.getWidth)
        card.setHeight(deck.getHeight)
        destination.addComponent(card)
        
        # we save the model data directly into the component so we don't need to keep track of it. Later when we
        # need to check the card type a user touched we can just use getClientProperty
        card.putClientProperty("card", currentCard)
        destination.getParent.animateHierarchyAndWait(400)
        card.setDraggable(true)
        
        # when the user drops a card on a drop target (currently only the deck) we remove it and animate it out
        card.addDropListener do |evt|
            
            evt.consume
            card.getParent.removeComponent(card)
            destination.animateLayout(300)
            
        end
    end
    
    def stop:void
        @current = Display.getInstance.getCurrent
    end
    
    def destroy():void
    end
end
    
class Card 
    attr_reader suite:char,
        rank:int

    def initialize(suite:char, rank:int) 
        @suite = suite
        @rank = rank
    end

    def rankToString:String
        if @rank > 10
            if @rank==11
                "j"
            elsif @rank==12
                "q"
            elsif @rank==13
                "k"
            elsif @rank==14
                "a"
            end
        else
            "" + rank
        end
    end

    def getFileName:String
        "#{rankToString}#{suite}.png"
    end
end


