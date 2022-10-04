//
//  SlashCommandEvent.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

public class SlashCommandEvent: InteractionEvent {

    public var channelId: Snowflake

    private let data: [String: Any]

    public let interactionId: Snowflake

    public let swiftcord: SwiftcordClient

    public let token: String

    /// Guild object for this channel
    public var guild: Guild? {
        return self.swiftcord.getGuild(for: channelId)
    }

    public let name: String

    public var member: Member?

    public let user: User

    public var options: SlashCommandEventOptions = [:]

    public var ephemeral: Int

    public var isDefered: Bool

    init(_ swiftcord: SwiftcordClient, data: [String: Any]) {
        // Store the data for later
        self.data = data

        let optionsData = data["data"] as! [String: Any]

        self.name = optionsData["name"] as! String
        
        let resolvedData = optionsData["resolved"] as? [String: Any]
        let users = (resolvedData?["users"] as? [String: [String: Any]])?.mapValues({ user in
            User(swiftcord, user)
        }) ?? [:]
        let channels = (resolvedData?["channels"] as? [String: [String: Any]])?.mapValues({ channel in
            GuildText(swiftcord, channel) as Channel
        }) ?? [:]
        let roles = (resolvedData?["roles"] as? [String: [String: Any]])?.mapValues({ role in
            Role(role)
        }) ?? [:]
        let attachments = (resolvedData?["attachments"] as? [String: [String: Any]])?.mapValues({ attachment in
            Attachment(attachment)
        }) ?? [:]

        if let options = optionsData["options"] as? [[String: Any]] {
            self.options = .create(
                data: options, users: users, channels: channels, roles: roles, attachments: attachments
            )
        }

        self.channelId = Snowflake(data["channel_id"])!

        if let userJson = data["member"] as? [String: Any] {
            self.user = User(swiftcord, userJson["user"] as! [String: Any])
        } else {
            self.user = User(swiftcord, data["user"] as! [String: Any])
        }


        self.swiftcord = swiftcord
        self.token = data["token"] as! String

        self.interactionId = Snowflake(data["id"] as! String)!

        self.ephemeral = 0
        self.isDefered = false

        self.member = nil
        if let guild = guild {
            self.member = Member(swiftcord, guild, data["member"] as! [String: Any])
        }
    }
    
    public func getOption<T>(_ named: String) -> T? {
        options.get(named)
    }
}

public indirect enum SlashCommandEventValue {
    
    case subCommand(SlashCommandEventOptions)
    case subCommandGroup(SlashCommandEventOptions)
    
    case integer(Int)
    case number(Double)
    case boolean(Bool)
    case string(String)
    
    case user(Snowflake, User?)
    case channel(Snowflake, Channel?)
    case role(Snowflake, Role?)
    case mentionable(Snowflake)
    
    case attachment(String, Attachment?)
    
    case unknown(String?)
    
    init(
        data: [String: Any],
        users: [String: User],
        channels: [String: Channel],
        roles: [String: Role],
        attachments: [String: Attachment]
    ) {
        let type = ApplicationCommandType(rawValue: data["type"] as! Int)!

        var value: SlashCommandEventValue?
        switch type {
        case .int:
            if let data = data["value"] as? Int {
                value = .integer(data)
            }
        case .number:
            if let data = data["value"] as? Double {
                value = .number(data)
            }
        case .bool:
            if let data = data["value"] as? Bool {
                value = .boolean(data)
            }
        case .string:
            if let data = data["value"] as? String {
                value = .string(data)
            }
        case .user:
            if let data = data["value"] as? UInt64 {
                let userData = users[String(data)]
                value = .user(Snowflake(data), userData)
            }
        case .channel:
            if let data = data["value"] as? UInt64 {
                let channelData = channels[String(data)]
                value = .channel(Snowflake(data), channelData)
            }
        case .role:
            if let data = data["value"] as? UInt64 {
                let roleData = roles[String(data)]
                value = .role(Snowflake(data), roleData)
            }
        case .mentionable:
            if let data = data["value"] as? UInt64 {
                value = .mentionable(Snowflake(data))
            }
        case .attatchment:
            if let data = data["value"] as? String {
                let attachmentData = attachments[data]
                value = .attachment(data, attachmentData)
            }
        case .subCommand:
            if let data = data["options"] as? [[String: Any]] {
                value = .subCommand(
                    SlashCommandEventOptions.create(
                        data: data,
                        users: users,
                        channels: channels,
                        roles: roles,
                        attachments: attachments
                    )
                )
            }
        case .subCommandGroup:
            if let data = data["options"] as? [[String: Any]] {
                value = .subCommandGroup(
                    SlashCommandEventOptions.create(
                        data: data,
                        users: users,
                        channels: channels,
                        roles: roles,
                        attachments: attachments
                    )
                )
            }
        }
        if value == nil {
            value = .unknown(data["value"] as? String)
        }
        
        self = value!
    }
}

public typealias SlashCommandEventOptions = [String: SlashCommandEventValue]

public extension SlashCommandEventOptions {
    func get<T>(_ named: String) -> T? {
        guard let value = self[named] else {
            return nil
        }
        
        switch value {
        case .subCommand(let value):
            return value as? T
        case .subCommandGroup(let value):
            return value as? T
        case .integer(let value):
            return value as? T
        case .number(let value):
            return value as? T
        case .boolean(let value):
            return value as? T
        case .string(let value):
            return value as? T
        case .user(let value, let value2):
            return (value as? T) ?? value2 as? T
        case .channel(let value, let value2):
            return (value as? T) ?? value2 as? T
        case .role(let value, let value2):
            return (value as? T) ?? value2 as? T
        case .mentionable(let value):
            return value as? T
        case .attachment(let value, let value2):
            return (value as? T) ?? value2 as? T
        case .unknown(let value):
            return value as? T
        }
    }
    
    static func create(
        data: [[String: Any]],
        users: [String: User],
        channels: [String: Channel],
        roles: [String: Role],
        attachments: [String: Attachment]
    ) -> SlashCommandEventOptions {
        var options: SlashCommandEventOptions = [:]
        for option in data {
            if let name = option["name"] as? String,
               let data = option["data"] as? [String: Any] {
                options[name] = SlashCommandEventValue(
                    data: data,
                    users: users,
                    channels: channels,
                    roles: roles,
                    attachments: attachments
                )
            }
        }
        return options
    }
}
