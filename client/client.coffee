Session.set "eventId" -1
# Set up Backbone router
Router = Backbone.Router.extend
	routes:
		""			: "home"
		"*eventId"	: "loadEvent"

	home: () -> Session.set "eventId", null

	loadEvent: (eventId) ->
		Session.set "eventId", eventId
		false

@app = new Router
Backbone.history.start {pushState: true}

# Window resize event
Session.set "windowHeight", $(window).height()
$(window).resize () ->
	Session.set "windowHeight", $(window).height()

# Event template
Template.event.event = () -> 
	Events.findOne {_id : Session.get "eventId"}, {name : 1}

Template.event.debts = () ->
	debts = Debts.find {eventId : Session.get "eventId"}

updateEvent = (name) -> Events.update {_id : Session.get("eventId")}, {$set : {name : name}}
Template.event.events =
	# Change event name
	"dblclick .hide-on-edit" : (event) ->
		editable = $(event.srcElement.parentNode)
		editable.addClass "editing"
		input = editable.find("input")
		input[0].value = event.srcElement.innerText
		input.focus()
	"blur .edit input" : (event) ->
		$(event.srcElement.parentNode).removeClass "editing"
		updateEvent(event.srcElement.value)
	"keypress .edit input" : (event) -> 
		$(event.srcElement.parentNode).removeClass "editing"
		updateEvent(event.srcElement.value) if event.keyCode == 13 # enter

Template.main.isHome = () ->
	eventId = Session.get "eventId";
	eventId == null || eventId == ""

Template.home.events = 
	"keyup input"	: (event) ->
		textBoxValue = $("input")[0].value
		$("button").attr "disabled",
			(textBoxValue == null || textBoxValue.trim() == "") ? "disabled" : null

	"click button"	: (event) -> 
		textBoxValue = $("input")[0].value
		if textBoxValue
			newId = Events.insert {name: textBoxValue}
			@app.navigate newId, true
		false

Template.participants.rendered = () ->
	console.log "participants rendered"

	Meteor.autorun () ->
		participantData = Participants.find({eventId : Session.get "eventId"}).fetch()

		container = $(".participant-group")
		width = container.width()
		height = Session.get("windowHeight") * 0.8
		container.height(height)
		radius = Math.min(width, height) * 0.35
		nItems = participantData.length
		angleIncrease = 2 * Math.PI / nItems

		console.log "#{width}, #{height}"

		# The selection to work on
		participants = d3
			.select(".participant-group")
			.selectAll(".participant")
			.data participantData, (d) -> d._id if d?

		# Create an element
		participants.enter()
			.append("div")
				.classed("participant", true)
				.html (d, i) -> Template.participant({participant : d})

		participants
			.transition()
				.duration(250)
				.attr "style", (d, i) ->
					el = $(this)
					x = radius * Math.cos(angleIncrease * i) + width / 2 - el.width() / 2
					y = radius * Math.sin(angleIncrease * i) + height / 2 - el.height() / 2
					"left:#{x}px; top:#{y}px"

dragSource = null
dragDestinations = []
Template.participants.events
	# New participant
	"click button" : (event) -> 
		event.preventDefault()
		nameTextBox = $("#participant-name")[0]
		emailTextBox = $("#participant-email")[0]
		addParticipant nameTextBox.value, emailTextBox.value
		nameTextBox.value = null
		emailTextBox.value = null

	# Drag and drop between participants
	"dragstart .participant" : (event) ->
		event.preventDefault()
	"mousedown .participant" : (event) -> 
		console.log "mouse down participant"
		return if event.which != 1 # Left mouse button

		# Reset some stuff
		$(".drag-over").removeClass("drag-over")
		dragDestinations = []

		borrower = d3.select(event.currentTarget).datum()
		dragSource = borrower
	"mouseup" : (event) -> 
		return if event.which != 1 # Left mouse button
		console.log "mouse up"
		$(".drag-over").removeClass("drag-over")

		try
			dragDestinations.forEach (borrower) ->
				Debts.insert
					eventId : Session.get "eventId"
					financierId : dragSource._id
					financierName : dragSource.name
					financierAvatarHash : dragSource.hash
					borrowerId : borrower._id
					borrowerName : borrower.name
					borrowerAvatarHash : borrower.hash
		finally
			dragSource = null
			dragDestinations = []
	"mouseenter .participant" : (event) ->
		return unless dragSource?
		event.preventDefault()
		event.stopPropagation()
		borrower = d3.select(event.currentTarget).datum()
		return if borrower == dragSource

		$(event.srcElement).toggleClass("drag-over")
		if borrower in dragDestinations
			dragDestinations.remove(borrower)
		else
			dragDestinations.push(borrower)

removeParticipant = (participant) -> Participants.remove participant

exitEditMode = (context, event) ->
	Participants.update {_id: context._id}, {$set: {name: event.srcElement.value}}
	$(event.srcElement.parentNode.parentNode).removeClass "editing"

renderParticipants = () ->
	console.log "rendering participants"

addParticipant = (name, email) ->
	console.log "adding participant"
	Meteor.call "addParticipant", {eventId : Session.get("eventId"), name : name, email : email}, (ret) ->
		console.log "adding done: #{ret}"

saveDebt = (id, name, amount) ->
	Debts.update({_id : id, $set : {name : name, amount : amount}})

