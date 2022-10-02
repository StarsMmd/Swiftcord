//
//  Webhook.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// Webhook structure
public struct Webhook {

    // MARK: Properties

    /// Parent class
    public internal(set) weak var swiftcord: SwiftcordClient?

    /// Avatar for the webhook in base64
    public let avatar: String?

    /// The `GuildText` this webhook messages to
    public let channel: GuildText

    /// The Guild this webhook is located in
    public internal(set) weak var guild: Guild?

    /// The id of the webhook
    public let id: Snowflake

    /// The display name of the webhook
    public let name: String

    /// The user account for this webhook
    public let user: User?

    /// The token for this webhook
    public let token: String

    // MARK: Initializer

    /**
     Creates Webhook structure

     - parameter swiftcord: The parent class
     - parameter json: The data to transform to a webhook
     */
    init(_ swiftcord: SwiftcordClient, _ json: [String: Any]) {
        self.swiftcord = swiftcord

        self.avatar = json["avatar"] as? String

        let channelId = Snowflake(json["channel_id"])!
        self.channel = swiftcord.guilds[
            swiftcord.getGuild(for: channelId)!.id
        ]!.channels[channelId]! as! GuildText

        self.guild = swiftcord.getGuild(for: channelId)!

        self.id = Snowflake(json["id"])!
        self.name = json["name"] as! String

        if let user = json["user"] as? [String: Any] {
            self.user = User(swiftcord, user)
        } else {
            self.user = nil
        }

        self.token = json["token"] as! String
    }

    /// Deletes the current webhook from its guild
    public func delete() async throws {
        try await self.swiftcord?.deleteWebhook(self.id, token: self.token)
    }

    /**
     Executes a webhook

     #### Content Dictionary Params ####

     - **content**: Message to send
     - **username**: The username the webhook will send with the message
     - **avatar_url**: The url of the user the webhook will send
     - **tts**: Whether or not this message is tts
     - **file**: The url of the image to send
     - **embed**: The embed object to send. Refer to [Embed structure](https://discord.com/developers/docs/resources/channel#embed-object)

     - parameter content: String or dictionary containing message content
     */
    /*public func execute(
        with content: Any
    ) async throws {
        try await self.swiftcord?.executeWebhook(self.id, token: self.token, with: content)
    }*/

    /**
     Executs a slack style webhook

     #### Content Params ####

     Refer to the [slack documentation](https://api.slack.com/incoming-webhooks) for their webhook structure

     - parameter content: Dictionary containing slack webhook info
     */
    public func executeSlack(
        with content: [String: Any]
    ) async throws {
        try await self.swiftcord?.executeSlackWebhook(self.id, token: self.token, with: content)
    }

    /**
     Modifies the current Webhook

     #### Option Params ####

     - **name**: The name of the webhook
     - **avatar**: The avatar for this webhook in base64 string

     - parameter options: A dictionary of options to apply to this webhook
     */
    public func modify(
        with options: [String: String]
    ) async throws -> Webhook? {
        return try await self.swiftcord?.modifyWebhook(self.id, token: self.token, with: options)
    }

}
