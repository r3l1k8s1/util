local TaskLibrary = {}
TaskLibrary.__index = TaskLibrary

function TaskLibrary.New()
    local self = setmetatable({}, TaskLibrary)
    self.Tasks = {}

    return self
end

function TaskLibrary:Add(ID, Task)
    self.Tasks[ID] = Task

    return self
end

function TaskLibrary:Get(ID)
    return self.Tasks[ID]
end

function TaskLibrary:Cancel(ID)
    local Tasks = self.Tasks

    task.cancel(Tasks[ID])
    Tasks[ID] = nil

    return self
end

function TaskLibrary:ClearTasks()
    for _, Task in pairs(self.Tasks) do
        task.cancel(Task)
    end

    table.clear(self.Tasks)

    return self
end

function TaskLibrary:Destroy()
    self:ClearTasks()

    setmetatable(self, nil)
end

return TaskLibrary
