import Foundation

public class MessageBuilder: Encodable {
    public var content: String?
    public var embeds: [EmbedBuilder]?
    public var components: [ActionRow<Button>]?

    public init(message: String) {
        self.content = message
        self.embeds = nil
        self.components = []
    }

    public func addComponent(component: ActionRow<Button>) -> Self {
        if components == nil {
            components = [ActionRow]()
        }
        guard components!.count < 5 else {
            return self
        }
        components?.append(component)
        return self
    }
    
    public func setMessageContent(_ content: String?) -> Self {
        self.content = content
        return self
    }
    
    public func addEmbed(_ embed: EmbedBuilder) -> Self {
        if embeds == nil {
            embeds = [EmbedBuilder]()
        }
        guard embeds!.count < 10 else {
            return self
        }
        embeds?.append(embed)
        return self
    }
    
    public func addEmbeds(_ embeds: [EmbedBuilder]) -> Self {
        var result = self
        for embed in embeds {
            result = result.addEmbed(embed)
        }
        return result
    }
}
