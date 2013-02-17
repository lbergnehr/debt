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

# Event template
Template.event.event = () -> 
	Events.findOne {_id : Session.get "eventId"}, {name : 1}

Template.event.debts = () ->
	Debts.find {eventId : Session.get "eventId"}

saveDebt = (id, name, amount) ->
	Debts.update({_id : id, $set : {name : name, amount : amount}})

Template.event.events =
	# # Remove debt
	# "click .remove-participant" : (event) -> 
	# 	console.log "removing participant #{this.name}."
	# 	removeParticipant this

	# Edit participant name
	"dblclick span.hide-on-edit" : (event) ->
		editable = $(event.srcElement.parentNode)
		editable.addClass "editing"
		editable.find("input").focus()

	"blur .edit input" : (event) -> saveDebt this._id, this.name, this.amount

	"keypress .edit input" : (event) -> saveDebt this, this.name, this.amount if event.keyCode == 13 # enter

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
	self = this

	# Drag behavior
	dragSource = null
	dragDestination = null
	drag = d3.behavior.drag()
		.on "dragstart",  (d, i) -> 
			console.log "dragging from: #{d.name}"
			dragSource = d
		.on "dragend", (d, i) ->
			console.log "stopped dragging from: #{d.name}"
			if dragDestination
				d3.select(".drag-over").classed("drag-over", false)
				console.log "dragged from #{dragSource.name} to #{dragDestination.name}"
				Debts.insert
					eventId : Session.get "eventId"
					financierId : dragSource._id
					financierName : dragSource.name
					borrowerId : dragDestination._id
					borrowerName : dragDestination.name

			dragSource = null
			dragDestination = null

	Meteor.autorun () ->
		participantData = Participants.find({eventId : Session.get "eventId"}).fetch()
		nItems = participantData.length

		node = $("svg")
		width = node.width()
		height = node.height()
		radius = Math.min(width, height) * 0.4
		angleIncrease = 2 * Math.PI / nItems

		# The selection to work on
		participants = d3
			.select("svg")
			.select("g")
				.attr("transform", "translate(#{width / 2}, #{height / 2})")
			.selectAll("g")
			.data(participantData, (d) -> d._id)

		scaleFactor = 0.1
		# Create an element
		participants.enter()
			.append("g")
				.attr("class", "participant-group")
				.each (d, i) ->
					el = d3.select this
					self = this

					# Group with elements
					group = el.append("g")
						.each () ->
							el2 = d3.select this
							# el2.append("circle")
							# 	.attr("r", "40%")
							# 	.classed("participant")
							el2.append("image")
								.attr("xlink:href", "http://www.gravatar.com/avatar/#{d.hash}")
								.attr("width", "100%").attr("height", "100%")
							el2.append("text").text((d) -> d.name)

					# Border rect
					rect = el.append("rect")
						.attr("width", "100%").attr("height", "100%")
					bbox = rect.node().getBBox()
					rect.attr("x", -bbox.width / 2).attr("y", -bbox.height / 2)
			.call(drag)
			.on "mouseover", (d, i) ->
				if (dragSource != null && dragSource != d)
					d3.select(this).classed("drag-over", true)
					dragDestination = d
			.on "mouseout", (d, i) ->
				d3.select(this).classed("drag-over", false)
				dragDestination = null

		participants
			.transition()
				.duration(250)
				.attr "transform", (d, i) ->
					x = radius * Math.cos(angleIncrease * i)
					y = radius * Math.sin(angleIncrease * i)
					"translate(#{x}, #{y}) scale(#{scaleFactor})"

dragSource = null
Template.participants.events = 
	# New participant
	"click button" : (event) -> 
		event.preventDefault()
		nameTextBox = $("#participant-name")[0]
		emailTextBox = $("#participant-email")[0]
		addParticipant nameTextBox.value, emailTextBox.value
		nameTextBox.value = null
		emailTextBox.value = null

	# Drag and drop between participants
	"dragstart .participant": (event) -> dragSource = this
	"dragover .participant"	: (event) ->
		event.srcElement.classList.add "drag-over" unless this == dragSource
		event.preventDefault()
		false
	"dragleave .participant": (event) ->
		event.srcElement.classList.remove "drag-over" unless this == dragSource 
	"drop .participant"		: (event) -> 
		unless this == dragSource
			console.log event
			event.srcElement.classList.remove "drag-over"
			addDebt dragSource, this, event.target

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











