class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "room_#{params[:room_id]}"
    Rails.logger.info "subscribed: #{params.inspect}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def say_hi
    ActionCable.server.broadcast("room", "Hello")
  end

  def create_message(message_params)
    Rails.logger.info("create_message: #{message_params.inspect}. Params: #{params.inspect}")

    @message = Message.new(message_params.slice('body', 'username'))
    @message.room_id = params[:room_id]
    @message.username = current_user.username

    data = {}

    if @message.save
      data[:html] = render_message(@message)
    else
      data[:html] = "Error: #{@message.errors.full_messages.to_sentence}"
    end

    ActionCable.server.broadcast("room", data)
  end

  def delete_message(params)
    Rails.logger.info "delete_message: #{params}"
    @message = Message.find(params['id'])
    @message.destroy

    ActionCable.server.broadcast("room", {deletedId: @message.id})
  end

  def render_message(message)
    ApplicationController.render partial: 'messages/message', locals: {message: message}
  end
end
