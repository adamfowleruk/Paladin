-- Definitions and Utilities for PObGen

------------------------------------------------------------------------------
-- Type conversion definitions
BePTypeTable = {}
BePTypeTable.bool = "bool"
BePTypeTable["const char *"] = "string"
BePTypeTable.BString = "string"
BePTypeTable["char *"] = "string"
BePTypeTable.char = "char"
BePTypeTable.int8 = "int"
BePTypeTable.int16 = "int"
BePTypeTable.int32 = "int"
BePTypeTable.int64 = "int"
BePTypeTable.uint8 = "int"
BePTypeTable.uint16 = "int"
BePTypeTable.uint32 = "int"
BePTypeTable.uint64 = "int"
BePTypeTable.rgb_color = "color"
BePTypeTable.BPoint = "point"
BePTypeTable.BRect = "rect"
BePTypeTable.float = "float"
BePTypeTable.double = "double"

PTypeBeTable = {}
PTypeBeTable.bool = "bool"
PTypeBeTable.string = "BString"
PTypeBeTable.char = "char"
PTypeBeTable.int8 = "int8"
PTypeBeTable.int16 = "int16"
PTypeBeTable.int32 = "int32"
PTypeBeTable.int64 = "int64"
PTypeBeTable.color = "rgb_color"
PTypeBeTable.point = "BPoint"
PTypeBeTable.rect = "BRect"
PTypeBeTable.float = "float"
PTypeBeTable.double = "double"
PTypeBeTable.pointer = "void *"

PTypeConstantTable = {}
PTypeConstantTable.bool = "PARG_BOOL"
PTypeConstantTable.string = "PARG_STRING"
PTypeConstantTable.int8 = "PARG_INT8"
PTypeConstantTable.int16 = "PARG_INT16"
PTypeConstantTable.int32 = "PARG_INT32"
PTypeConstantTable.int64 = "PARG_INT64"
PTypeConstantTable.uint8 = "PARG_INT8"
PTypeConstantTable.uint16 = "PARG_INT16"
PTypeConstantTable.uint32 = "PARG_INT32"
PTypeConstantTable.uint64 = "PARG_INT32"
PTypeConstantTable.color = "PARG_COLOR"
PTypeConstantTable.point = "PARG_POINT"
PTypeConstantTable.rect = "PARG_RECT"
PTypeConstantTable.float = "PARG_FLOAT"
PTypeConstantTable.double = "PARG_DOUBLE"
PTypeConstantTable.char = "PARG_CHAR"

------------------------------------------------------------------------------
-- Code Templates and associated methods
--[[
	The following code uses placeholders. Each placeholder is enclosed in %().
	Here are the existing used placeholders and their uses
	POBJECTNAME = the name of the PObject class. Corresponds with PObject.name
					in the Lua-based template files

	POBJECT_PARENT_NAME = name of the PObject's parent class
	POBJECT_FRIENDLY_NAME = "friendly" name for the control, such as "Slider"
							which is not necessarily the name of the class
	POBJECT_PARENT_HEADER = the header of the pobject's parent class
	
	BACKENDNAME = name of the backend class
	BACKEND_PARENT_NAME = name of the backend's parent class
	BACKEND_CLASS_DECL = the declaration of the backend's class
	BACKEND_FVIEW_NAME = the name of the backend variable. fView if
						the object inherits PView, fBackend if not.
	
	HEADER_GUARD = name of the constant used for the header guard
	
	PBOJECT_GET_BACKEND = placeholder code related to GetBackend()
	
	USESVIEW_CONSTRUCTOR = a utility placeholder for removing the view construction code
	USESVIEW_BYPASSVIEW = another utility placeholder for skipping the backend by views
						which inherit from PView directly
	USESVIEW_BYPASSVIEW2 = as the first, but with a comma prefix
]]


PObjectMainCode = [[
%(POBJECTNAME)::%(POBJECTNAME)(void)
	:	%(POBJECT_PARENT_NAME)(%(USESVIEW_BYPASSVIEW))
{
	fType = "%(POBJECTNAME)";
	fFriendlyType = "%(POBJECT_FRIENDLY_NAME)";
	AddInterface("%(POBJECTNAME)");
	
	InitBackend();
	InitProperties();
	InitMethods();
}


%(POBJECTNAME)::%(POBJECTNAME)(BMessage *msg)
	:	%(POBJECT_PARENT_NAME)(msg%(USESVIEW_BYPASSVIEW2))
{
	fType = "%(POBJECTNAME)";
	fFriendlyType = "%(POBJECT_FRIENDLY_NAME)";
	AddInterface("%(POBJECTNAME)");
	
	%(USESVIEW_CONSTRUCTOR)
	
	InitBackend();
}


%(POBJECTNAME)::%(POBJECTNAME)(const char *name)
	:	%(POBJECT_PARENT_NAME)(name%(USESVIEW_BYPASSVIEW2))
{
	fType = "%(POBJECTNAME)";
	fFriendlyType = "%(POBJECT_FRIENDLY_NAME)";
	AddInterface("%(POBJECTNAME)");
	
	InitMethods();
	InitBackend();
}


%(POBJECTNAME)::%(POBJECTNAME)(const %(POBJECTNAME) &from)
	:	%(POBJECT_PARENT_NAME)(from%(USESVIEW_BYPASSVIEW2))
{
	fType = "%(POBJECTNAME)";
	fFriendlyType = "%(POBJECT_FRIENDLY_NAME)";
	AddInterface("%(POBJECTNAME)");
	
	InitMethods();
	InitBackend();
}


%(POBJECTNAME)::~%(POBJECTNAME)(void)
{
}


BArchivable *
%(POBJECTNAME)::Instantiate(BMessage *data)
{
	if (validate_instantiation(data, "%(POBJECTNAME)"))
		return new %(POBJECTNAME)(data);

	return NULL;
}


PObject *
%(POBJECTNAME)::Create(void)
{
	return new %(POBJECTNAME)();
}


PObject *
%(POBJECTNAME)::Duplicate(void) const
{
	return new %(POBJECTNAME)(*this);
}
]]


function ApplyObjectPlaceholders(str, def)
	if (not def) then
		return str
	end
	
	local out = str
	
	if (def.object.UsesView) then
		
		local msgCode = [[BMessage viewmsg;
	if (msg->FindMessage("backend", &viewmsg) == B_OK)
		fView = (BView*)]]
		
		msgCode = msgCode .. def.backend.Name .. "::Instantiate(&viewmsg);\n"
		
		out = string.gsub(out, "%%%(USESVIEW_CONSTRUCTOR%)", msgCode)
	else
		out = string.gsub(out, "%%%(USESVIEW_CONSTRUCTOR%)", "")
	end
	
	out = string.gsub(out, "%%%(POBJECTNAME%)", def.object.Name)
	out = string.gsub(out, "%%%(POBJECT_PARENT_NAME%)", def.object.ParentClass)
	out = string.gsub(out, "%%%(POBJECT_PARENT_HEADER%)", def.global.ParentHeaderName)
	out = string.gsub(out, "%%%(POBJECT_FRIENDLY_NAME%)", def.object.FriendlyName)
	
	return out
end


function ApplyBackendPlaceholders(str, obj, back)
	if (not back) then
		return str
	end
	
	local out = string.gsub(str, "%%%(BACKENDNAME%)", def.backend.Name)
	
	local parentPattern = def.backend.name
	if (def.backend.parent) then
		parentPattern = def.backend.parent
	end
	out = string.gsub(out, "%%%(BACKEND_PARENT_NAME%)", parentPattern)
	
	local fViewName = ""
	if (def.object.UsesView) then
		fViewName = "fView"
	else
		fViewName = "fBackend"
	end
	out = string.gsub(out, "%%%(BACKEND_FVIEW_NAME%)", fViewName)
	
	return out
end


function ApplyCustomPlaceholder(str, placeholder, replace)
	if (not placeholder) then
		return str
	end
	local escaped = string.gsub(placeholder, "([%%%(%)])", "%%%1")
	return string.gsub(str, escaped, replace)
end


------------------------------------------------------------------------------
-- Utility function definitions

-- pair() and triplet() are syntactic sugar for the definition files
function pair(k, v)
	return { ["key"] = k, ["value"] = v }
end


function triplet(k, v, d, f)
	return { ["key"]=k, ["value"]=v, ["description"]=d, ["flags"]=f }
end


function param(name, type, callType, callIndex, desc, flags)
	local t = {}
	
	t.name = name
	t.type = type
	t.callIndex = callIndex
	t.callType = callType
	t.description = desc
	t.flags = flags
	
	return t
end


function BeToPType(typeName)
	local out = BePTypeTable[typeName]
	if (out) then
		return out
	end
	
	if (string.sub(typeName, -1) == "*") then
		return "pointer"
	end
	
	return nil
end


function PTypeToBe(typeName)
	return PTypeBeTable[typeName]
end

function PTypeToConstant(typeName)
	local out = PTypeConstantTable[typeName]
	if (out) then
		return out
	end
	
	if (string.sub(typeName, -1) == "*") then
		return "PARG_POINTER"
	end
	
	return nil
end


function TypeToPropertyClass(str)
	if (str == "int") then
		return "IntProperty"
	elseif (str == "bool") then
		return "BoolProperty"
	elseif (str == "string") then
		return "StringProperty"
	elseif (str == "rect") then
		return "RectProperty"
	elseif (str == "point") then
		return "PointProperty"
	elseif (str == "color") then
		return "ColorProperty"
	elseif (str == "float") then
		return "FloatProperty"
	elseif (str == "enum") then
		return "EnumProperty"
	else
		print("Unrecognized property type " .. str)
	end
	
	return nil
end