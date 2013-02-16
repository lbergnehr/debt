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

Template.event.event = () -> 
	Events.findOne {_id : Session.get "eventId"}, {name : 1}

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
	Meteor.autorun () ->
		data = Participants.find({eventId : Session.get "eventId"}).fetch()
		nItems = data.length
		console.log "Number of items: #{nItems}"

		node = $("svg")
		width = node.width()
		height = node.height()
		radius = Math.min(width, height) * 0.4
		angleIncrease = 2 * Math.PI / nItems
		console.log "Radius: #{radius}"
		console.log "Angle increase: #{angleIncrease}"
		console.log "svg size: width: #{width}, height: #{height}"

		# The selection to work on
		participants = d3
			.select("svg")
			.select("g")
				.attr("transform", "translate(#{width / 2}, #{height / 2})")
			.selectAll("g")
			.data(data, (d) -> d._id)

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
							el2.append("circle", ":first-child")
								.attr("r", "40%")
								.attr("class", "participant")
							el2.append("text").text((d) -> d.name)

					# Border rect
					rect = el.append("rect")
						.attr("width", "100%").attr("height", "100%")
					bbox = rect.node().getBBox()
					rect.attr("x", -bbox.width / 2).attr("y", -bbox.height / 2)

		participants
			.transition()
				.duration(250)
				.attr "transform", (d, i) ->
					x = radius * Math.cos(angleIncrease * i)
					y = radius * Math.sin(angleIncrease * i)
					"translate(#{x}, #{y}) scale(#{scaleFactor})"

# Template.participant.events =
# 	# Remove participant
# 	"click .remove-participant" : (event) -> 
# 		console.log "removing participant #{this.name}."
# 		removeParticipant this

# 	# Edit participant name
# 	"dblclick span"	: (event) ->
# 		editable = $(event.srcElement.parentNode)
# 		editable.addClass "editing"
# 		editable.find("input").focus()

# 	"blur .edit input" : (event) -> exitEditMode this, event
# 	"keypress .edit input" : (event) -> exitEditMode this, event if event.keyCode == 13 # enter

dragSource = null
Template.participants.events = 
	# New participant
	"click button" : (event) -> 
		textBox = $("#participant-name")[0]
		addParticipant textBox.value
		textBox.value = null
		false

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

addDebt = (financier, borrower, element) ->
	context = 
		financier	: financier.name
		borrower	: borrower.name

	html = Template.amountPopover context

	target = $(element)
	target.popover 
		trigger	: "manual"
		html	: true
		title	: "Amount"
		content	: html

	target.popover "show"

	el = $(".popover")

	amountInput = el.find(".borrowed-amount")[0]
	amountInput.focus()

	doc = $(document)
	doc.on "mouseup", (e) ->
		console.log "document mouseup"
		if el.has(e.target).length == 0
			target.popover "destroy"
			exit()

	el.find("input.btn").on "click", (e) ->
		e.preventDefault()
		expense = el.find(".expense")[0].value
		target.popover "destroy"

		financier.borrowings = [] if !financier.borrowings
		financier.borrowings.push
			borrowerId : borrower._id
			borrowerName : borrower.name
			amount : parseFloat(amountInput.value) || 0
			expense : expense
		financier.totalExpenses = financier.borrowings.map((b) -> parseFloat(b.amount) || 0).reduce((x, y) -> x + y)
		
		Participants.update {_id : financier._id}, {$set : {borrowings : financier.borrowings, totalExpenses : financier.totalExpenses }}

		exit()

	exit = () -> doc.unbind()

addParticipant = (name) ->
	Participants.insert name: name, eventId: Session.get "eventId"

