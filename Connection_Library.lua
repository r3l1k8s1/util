local ConnectionLibrary = {}
ConnectionLibrary.__index = ConnectionLibrary

function ConnectionLibrary.New()
    local self = setmetatable({}, ConnectionLibrary)
    self.Connections = {}

    return self
end

function ConnectionLibrary:Add(ID, Connection)
    self.Connections[ID] = Connection

    return self
end

function ConnectionLibrary:Get(ID)
    return self.Connections[ID]
end

function ConnectionLibrary:Disconnect(ID)
    local Connections = self.Connections

    Connections[ID]:Disconnect()
    Connections[ID] = nil

    return self
end

function ConnectionLibrary:ClearConnections()
    for _, Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end

    table.clear(self.Connections)

    return self
end

function ConnectionLibrary:Destroy()
    self:ClearConnections()

    setmetatable(self, nil)
end

return ConnectionLibrary
