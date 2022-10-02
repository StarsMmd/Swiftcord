//
//  GuildChannel.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation

/// GuildChannel Type
public class GuildText: GuildChannel, TextChannel, Updatable {

    // MARK: Properties

    /// Parent class
    public internal(set) weak var swiftcord: SwiftcordClient?

    /// Channel Category this channel belongs to
    public var category: GuildCategory? {
        guard let parentId = parentId else {
            return nil
        }

        return guild?.channels[parentId] as? GuildCategory
    }

    /// Guild object for this channel
    public var guild: Guild? {
        return self.swiftcord?.getGuild(for: id)
    }

    /// ID of the channel
    public let id: Snowflake

    /// Whether or not this channel is NSFW
    public internal(set) var isNsfw: Bool

    /// Last message sent's ID
    public internal(set) var lastMessageId: Snowflake?

    /// Last Pin's timestamp
    public internal(set) var lastPinTimestamp: Date?

    /// Name of channel
    public internal(set) var name: String?

    /// Parent Category ID of this channel
    public internal(set) var parentId: Snowflake?

    /// Array of Overwrite strcuts for channel
    public internal(set) var permissionOverwrites = [Snowflake: Overwrite]()

    /// Position of channel
    public internal(set) var position: Int?

    /// Topic of the channel
    public internal(set) var topic: String?

    /// Indicates what type of channel this is (.guildText or .guildVoice)
    public var type: ChannelType {
        return .guildText
    }

    // MARK: Initializer

    /**
     Creates a GuildText structure

     - parameter swiftcord: Parent class
     - parameter json: JSON represented as a dictionary
     */
    init(_ swiftcord: SwiftcordClient, _ json: [String: Any]) {
        self.swiftcord = swiftcord

        self.id = Snowflake(json["id"])!

        self.lastMessageId = Snowflake(json["last_message_id"])

        if let lastPinTimestamp = json["last_pin_timestamp"] as? String {
            self.lastPinTimestamp = lastPinTimestamp.date
        } else {
            self.lastPinTimestamp = nil
        }

        let name = json["name"] as? String
        self.name = name

        if let isNsfw = json["nsfw"] as? Bool {
            self.isNsfw = isNsfw
        } else if let name = name {
            self.isNsfw = name == "nsfw" || name.hasPrefix("nsfw-")
        } else {
            self.isNsfw = false
        }

        self.parentId = Snowflake(json["parent_id"])

        if let overwrites = json["permission_overwrites"] as? [[String: Any]] {
            for overwrite in overwrites {
                let overwrite = Overwrite(overwrite)
                self.permissionOverwrites[overwrite.id] = overwrite
            }
        }

        self.position = json["position"] as? Int
        self.topic = json["topic"] as? String

        if let guildId = Snowflake(json["guild_id"]) {
            swiftcord.guilds[guildId]!.channels[self.id] = self
        }
    }

    // MARK: Functions

    func update(_ json: [String: Any]) {
        self.lastMessageId = Snowflake(json["last_message_id"])

        if let lastPinTimestamp = json["last_pin_timestamp"] as? String {
            self.lastPinTimestamp = lastPinTimestamp.date
        } else {
            self.lastPinTimestamp = nil
        }

        let name = json["name"] as? String
        self.name = name

        if let isNsfw = json["nsfw"] as? Bool {
            self.isNsfw = isNsfw
        } else if let name = name {
            self.isNsfw = name == "nsfw" || name.hasPrefix("nsfw-")
        } else {
            self.isNsfw = false
        }

        self.parentId = Snowflake(json["parent_id"])

        if let overwrites = json["permission_overwrites"] as? [[String: Any]] {
            for overwrite in overwrites {
                let overwrite = Overwrite(overwrite)
                self.permissionOverwrites[overwrite.id] = overwrite
            }
        }

        self.position = json["position"] as? Int
        self.topic = json["topic"] as? String
    }

    /**
     Creates a webhook for this channel

     #### Options Params ####

     - **name**: The name of the webhook
     - **avatar**: The avatar string to assign this webhook in base64

     - parameter options: Preconfigured options to create this webhook with
     */
    public func createWebhook(
        with options: [String: String] = [:]
    ) async throws -> Webhook? {
        guard self.type != .guildVoice else { return nil }
        return try await self.swiftcord?.createWebhook(for: self.id, with: options)
    }

    /**
     Deletes all reactions from message

     - parameter messageId: Message to delete all reactions from
     */
    public func deleteReactions(
        from messageId: Snowflake
    ) async throws {
        guard self.type != .guildVoice else { return }
        try await self.swiftcord?.deleteReactions(from: messageId, in: self.id)
    }

    /// Gets this channel's webhooks
    public func getWebhooks() async throws -> [Webhook]? {
        guard self.type != .guildVoice else { return nil }
        return try await self.swiftcord?.getWebhooks(from: self.id)
    }

    public func createThread(
        for message: Snowflake,
        _ params: StartThreadData
    ) async throws -> ThreadChannel? {
        guard self.type != .guildVoice else { return nil }
        return try await self.swiftcord?.createThread(in: self.id, for: message, params)
    }

    public func createThread(
        _ params: StartThreadData
    ) async throws -> ThreadChannel? {
        guard self.type != .guildVoice else { return nil }
        return try await self.swiftcord?.createThread(in: self.id, params)
    }

}

/// Permission Overwrite Type
public struct Overwrite {

    // MARK: Properties

    /// Allowed permissions number
    public let allow: Int

    /// Denied permissions number
    public let deny: Int

    /// ID of overwrite
    public let id: Snowflake

    /// Either "role" or "member"
    public let type: Int

    // MARK: Initializer

    /**
     Creates Overwrite structure

     - parameter json: JSON representable as a dictionary
     */
    init(_ json: [String: Any]) {

        self.allow = Int(json["allow"] as! String)!
        self.deny = Int(json["deny"] as! String)!
        self.id = Snowflake(json["id"])!
        self.type = json["type"] as! Int
    }

}
