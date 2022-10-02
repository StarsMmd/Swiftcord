//
//  GuildVoice.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//

/// Representation of a guild voice channel
public class GuildVoice: GuildChannel, Updatable {

    // MARK: Properties

    /// Parent Class
    public internal(set) weak var swiftcord: SwiftcordClient?

    /// Bitrate (in bits) for channel
    public internal(set) var bitrate: Int?

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

    /// Name of channel
    public internal(set) var name: String?

    /// Parent Category ID of this channel
    public internal(set) var parentId: Snowflake?

    /// Collection of Overwrites mapped by `OverwriteID`
    public internal(set) var permissionOverwrites = [Snowflake: Overwrite]()

    /// Position of channel
    public internal(set) var position: Int?

    /// Indicates what type of channel this is (.guildVoice)
    public let type = ChannelType.guildVoice

    /// (Voice) User limit for voice channel
    public internal(set) var userLimit: Int?

    // MARK: Initializer

    /**
     Creates a GuildVoice structure

     - parameter swiftcord: Parent class
     - parameter json: JSON represented as a dictionary
     */
    init(_ swiftcord: SwiftcordClient, _ json: [String: Any]) {
        self.swiftcord = swiftcord

        self.bitrate = json["bitrate"] as? Int
        self.id = Snowflake(json["id"])!

        let name = json["name"] as? String
        self.name = name

        self.parentId = Snowflake(json["parent_id"])

        if let overwrites = json["permission_overwrites"] as? [[String: Any]] {
            for overwrite in overwrites {
                let overwrite = Overwrite(overwrite)
                self.permissionOverwrites[overwrite.id] = overwrite
            }
        }

        self.position = json["position"] as? Int
        self.userLimit = json["user_limit"] as? Int

        if let guildId = Snowflake(json["guild_id"]) {
            swiftcord.guilds[guildId]!.channels[self.id] = self
        }
    }

    // MARK: Functions

    func update(_ json: [String: Any]) {
        self.bitrate = json["bitrate"] as? Int

        let name = json["name"] as? String
        self.name = name

        self.parentId = Snowflake(json["parent_id"])

        if let overwrites = json["permission_overwrites"] as? [[String: Any]] {
            for overwrite in overwrites {
                let overwrite = Overwrite(overwrite)
                self.permissionOverwrites[overwrite.id] = overwrite
            }
        }

        self.position = json["position"] as? Int
        self.userLimit = json["user_limit"] as? Int
    }

    /**
     Moves a member in this voice channel to another voice channel (if they are in it)

     - parameter userId: User to move
     */
    public func moveMember(
        _ userId: Snowflake
    ) async throws {
        guard let guild = self.guild else { return }
        _ = try await self.swiftcord?.request(.modifyGuildMember(guild.id, userId), body: ["channel_id": self.id.description])
    }

}
