-- ================================================================
-- DgnTracker v1.3
-- Auteur : Tibiscui - Kirin Tor
-- ================================================================

local ADDON = "DgnTracker"
DgnTrackerData = DgnTrackerData or {}

DgnTrackerDB = DgnTrackerDB or {
  pos        = {point="CENTER", x=0, y=0},
  open       = false,
  extension  = "TheWarWithin",
  mmAngle    = 195,
  activeTab  = "dungeon",   -- onglet actif dans la fenêtre (dungeon/raid/delve/torghast/tourment)
  expandedInst = {},
}

-- ================================================================
-- CONSTANTES
-- ================================================================
local FRAME_W   = 700
local TAB_COL_W = 96
local TAB_H     = 28
local TAB_GAP   = 2

local EXT_ROW1 = {"Midnight","TheWarWithin","Dragonflight","Shadowlands","BattleForAzeroth","Legion"}
local EXT_ROW2 = {"WarlordsOfDraenor","MistsOfPandaria","Cataclysme","WrathOfTheLichKing","TheBurningCrusade","Vanilla"}

local EXT_LABELS = {
  Midnight="MID", TheWarWithin="TWW", Dragonflight="DF",
  Shadowlands="SL", BattleForAzeroth="BfA", Legion="LEG",
  WarlordsOfDraenor="WoD", MistsOfPandaria="MoP", Cataclysme="CATA",
  WrathOfTheLichKing="WotLK", TheBurningCrusade="TBC", Vanilla="VAN",
  Torghast="⚡Torghast",
}
local EXT_FULLNAMES = {
  Midnight="Midnight (12.0)", TheWarWithin="The War Within (11.0)",
  Dragonflight="Dragonflight (10.0)", Shadowlands="Shadowlands (9.0)",
  BattleForAzeroth="Battle for Azeroth (8.0)", Legion="Legion (7.0)",
  WarlordsOfDraenor="Warlords of Draenor (6.0)", MistsOfPandaria="Mists of Pandaria (5.0)",
  Cataclysme="Cataclysme (4.0)", WrathOfTheLichKing="Wrath of the Lich King (3.0)",
  TheBurningCrusade="The Burning Crusade (2.0)", Vanilla="Vanilla (1.0)",
  Torghast="Torghast - Tour des Damnés (SL 9.x)",
}
local EXT_TAB_COLORS = {
  Midnight={r=0.58,g=0.30,b=0.95}, TheWarWithin={r=0.55,g=0.75,b=0.95},
  Dragonflight={r=0.95,g=0.45,b=0.10}, Shadowlands={r=0.45,g=0.55,b=0.95},
  BattleForAzeroth={r=0.85,g=0.25,b=0.25}, Legion={r=0.60,g=0.15,b=0.85},
  WarlordsOfDraenor={r=0.85,g=0.50,b=0.10}, MistsOfPandaria={r=0.20,g=0.65,b=0.45},
  Cataclysme={r=0.95,g=0.35,b=0.10}, WrathOfTheLichKing={r=0.65,g=0.85,b=1.00},
  TheBurningCrusade={r=0.20,g=0.75,b=0.28},
  Torghast={r=0.75,g=0.20,b=0.85},
}

-- Couleurs officielles WoW par type
local TYPE_COLORS = {
  dungeon  = {r=0.30, g=0.70, b=1.00},   -- bleu clair
  raid     = {r=0.10, g=0.85, b=0.20},   -- VERT officiel WoW raids
  delve    = {r=0.90, g=0.65, b=0.10},   -- orange/doré
  torghast = {r=0.70, g=0.25, b=0.90},   -- violet
  tourment = {r=0.70, g=0.25, b=0.90},   -- violet
}
local TYPE_LABELS = {
  dungeon="Donjon", raid="Raid", delve="Gouffre", torghast="Tourment", tourment="Tourment",
}

-- Onglets internes globaux (Tourment uniquement dans Shadowlands via onglet Torghast)
local INNER_TABS = {"dungeon","raid","delve"}
local INNER_TAB_LABELS = {
  dungeon="Donjon", raid="Raid", delve="Gouffre",
}

local function hex(c) return math.floor((c or 0)*255) end

-- Torghast virtual tab : pioche les données type=torghast dans Shadowlands
local function GetTorghastInstances()
  local result = {}
  local slData = DgnTrackerData and DgnTrackerData["Shadowlands"]
  if slData and slData.instances then
    for _, inst in ipairs(slData.instances) do
      if inst.type == "torghast" then table.insert(result, inst) end
    end
  end
  return result
end

-- Retourne la liste ordonnée des onglets à afficher pour une extension
local function GetTabsForExt(extKey)
  -- Shadowlands : Donjon + Raid + Tourment (Torghast)
  if extKey == "Shadowlands" then
    return {"dungeon","raid","torghast"}
  end
  -- Torghast virtuel : uniquement Tourment
  if extKey == "Torghast" then
    return {"torghast"}
  end
  -- Autres extensions : Donjon + Raid + Gouffre selon dispo
  local available = {}
  local data = DgnTrackerData[extKey]
  local list = data and data.instances or {}
  local seen = {}
  for _, inst in ipairs(list) do
    seen[inst.type] = true
  end
  for _, t in ipairs({"dungeon","raid","delve"}) do
    if seen[t] then table.insert(available, t) end
  end
  return available
end

-- Labels des onglets (dont Tourment)
local ALL_TAB_LABELS = {
  dungeon="Donjon", raid="Raid", delve="Gouffre", torghast="Tourment",
}

-- ================================================================
-- CONSTRUCTION DE L'INTERFACE
-- ================================================================
local mainFrame

local function BuildUI()
  local CX  = TAB_COL_W + 18
  local CTW = FRAME_W - CX - 14

  -- ================================================================
  -- FENETRE PRINCIPALE
  -- ================================================================
  mainFrame = CreateFrame("Frame","DTMainFrame",UIParent,"BackdropTemplate")
  mainFrame:SetSize(FRAME_W, 600)
  mainFrame:SetFrameStrata("HIGH")
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:RegisterForDrag("LeftButton")
  mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
  mainFrame:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local point,_,_,x,y = s:GetPoint()
    DgnTrackerDB.pos = {point=point,x=x,y=y}
  end)
  mainFrame:SetScript("OnKeyDown", function(self,key)
    if key=="ESCAPE" then self:Hide(); DgnTrackerDB.open=false end
  end)
  mainFrame:EnableKeyboard(true)
  mainFrame:SetPropagateKeyboardInput(true)
  mainFrame:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=32,
    insets={left=11,right=12,top=12,bottom=11},
  })
  mainFrame:SetBackdropColor(0.04,0.02,0.06,0.97)
  mainFrame:SetBackdropBorderColor(0.72,0.60,0.28,1.0)

  -- ================================================================
  -- TITRE
  -- ================================================================
  local titleBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  titleBg:SetPoint("TOP",mainFrame,"TOP",0,14)
  titleBg:SetSize(430,44)
  titleBg:SetFrameLevel(mainFrame:GetFrameLevel()+2)
  titleBg:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=20,
    insets={left=7,right=7,top=7,bottom=7},
  })
  titleBg:SetBackdropColor(0.04,0.02,0.06,0.97)
  titleBg:SetBackdropBorderColor(0.72,0.60,0.28,1.0)

  local logoL = titleBg:CreateTexture(nil,"OVERLAY")
  logoL:SetSize(22,22)
  logoL:SetTexture("Interface\\AddOns\\DgnTracker\\medias\\DgnTracker")
  local logoR = titleBg:CreateTexture(nil,"OVERLAY")
  logoR:SetSize(22,22)
  logoR:SetTexture("Interface\\AddOns\\DgnTracker\\medias\\DgnTracker")

  local titleStr = titleBg:CreateFontString(nil,"OVERLAY")
  titleStr:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE")
  titleStr:SetPoint("CENTER",titleBg,"CENTER",0,5)
  titleStr:SetText("|cFFFFD700Tibi Dgn Tracker|r  |cFF9480FFInstances & Raids|r")
  logoL:SetPoint("RIGHT",titleStr,"LEFT",-6,0)
  logoR:SetPoint("LEFT",titleStr,"RIGHT",6,0)

  local byLine = titleBg:CreateFontString(nil,"OVERLAY")
  byLine:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
  byLine:SetPoint("TOP",titleStr,"BOTTOM",0,0)
  byLine:SetText("|cFFF58CBAby Tibiscui|r")

  local closeBtn = CreateFrame("Button",nil,mainFrame,"UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT",-5,-5)
  closeBtn:SetScript("OnClick",function() mainFrame:Hide(); DgnTrackerDB.open=false end)

  local drag = mainFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  drag:SetPoint("TOP",0,-30)
  drag:SetText("|cFF888888Glisser pour déplacer|r")

  local sepTop = mainFrame:CreateTexture(nil,"ARTWORK")
  sepTop:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepTop:SetPoint("TOPLEFT",12,-45)
  sepTop:SetPoint("TOPRIGHT",-12,-45)
  sepTop:SetHeight(1)
  sepTop:SetVertexColor(0.72,0.60,0.28,0.9)

  -- ================================================================
  -- COLONNE GAUCHE : ONGLETS EXTENSIONS
  -- ================================================================
  -- On calcule la hauteur nécessaire AVANT de créer le frame
  local totalRows = #EXT_ROW1 + #EXT_ROW2 + 1  -- +1 pour Torghast
  -- Hauteur col : 58 (en-tête) + rangées + séparateurs + torghast + marge bas
  local COL_CONTENT_H = 58
    + #EXT_ROW1 * (TAB_H+TAB_GAP)
    + 8   -- séparateur classique
    + #EXT_ROW2 * (TAB_H+TAB_GAP)
    + 10  -- séparateur Torghast
    + TAB_H + 14  -- Torghast + marge

  local tabColBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  tabColBg:SetPoint("TOPLEFT",12,-50)
  tabColBg:SetWidth(TAB_COL_W)
  tabColBg:SetHeight(COL_CONTENT_H)
  tabColBg:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=8, edgeSize=6,
    insets={left=2,right=2,top=2,bottom=2},
  })
  tabColBg:SetBackdropColor(0.02,0.01,0.04,0.85)
  tabColBg:SetBackdropBorderColor(0.72,0.60,0.28,0.35)
  mainFrame.tabColBg = tabColBg

  local extBtns = {}
  local extTabStartY = -58

  local function BuildExtTab(extKey, yOff)
    local col      = EXT_TAB_COLORS[extKey] or {r=0.5,g=0.5,b=0.5}
    local lbl      = EXT_LABELS[extKey] or extKey
    local fullName = EXT_FULLNAMES[extKey] or extKey
    local eb = CreateFrame("Button",nil,mainFrame,"BackdropTemplate")
    eb:SetPoint("TOPLEFT",14,yOff)
    eb:SetSize(TAB_COL_W-4,TAB_H)
    eb:SetBackdrop({
      bgFile="Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      tile=true, tileSize=8, edgeSize=6,
      insets={left=2,right=2,top=2,bottom=2},
    })
    eb:SetBackdropColor(col.r*0.12,col.g*0.12,col.b*0.12,0.95)
    eb:SetBackdropBorderColor(col.r*0.35,col.g*0.35,col.b*0.35,0.5)
    -- (accent bar supprimé)
    local eTxt = eb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    eTxt:SetPoint("LEFT",eb,"LEFT",8,0)
    eTxt:SetSize(TAB_COL_W-40,TAB_H-4)
    eTxt:SetText(string.format("|cFF%02X%02X%02X%s|r",hex(col.r),hex(col.g),hex(col.b),lbl))
    eTxt:SetWordWrap(false)
    eTxt:SetJustifyH("LEFT")
    local cntLbl = eb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    cntLbl:SetPoint("RIGHT",eb,"RIGHT",-4,0)
    cntLbl:SetJustifyH("RIGHT")
    eb.cntLbl = cntLbl
    eb.extKey = extKey
    eb.col    = col
    eb:SetScript("OnClick",function()
      DgnTrackerDB.extension = extKey
      -- Sélectionner automatiquement l'onglet "Donjon" à l'ouverture d'une ext
      DgnTrackerDB.activeTab = "dungeon"
      mainFrame:RefreshContent()
    end)
    eb:SetScript("OnEnter",function(s)
      GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
      GameTooltip:AddLine(fullName,col.r,col.g,col.b)
      local ed = (extKey=="Torghast") and {instances=GetTorghastInstances()} or DgnTrackerData[extKey]
      if ed and ed.instances then
        GameTooltip:AddLine(#ed.instances.." instance(s)",0.75,0.75,0.75)
      end
      GameTooltip:Show()
    end)
    eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
    table.insert(extBtns,eb)
    return eb
  end

  for i,extKey in ipairs(EXT_ROW1) do
    BuildExtTab(extKey, extTabStartY-(i-1)*(TAB_H+TAB_GAP))
  end

  local divOffsetY = extTabStartY - #EXT_ROW1*(TAB_H+TAB_GAP) - 3
  local sepDiv = mainFrame:CreateTexture(nil,"OVERLAY")
  sepDiv:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepDiv:SetPoint("TOPLEFT",mainFrame,"TOPLEFT",14,divOffsetY)
  sepDiv:SetSize(TAB_COL_W-4, 2)
  sepDiv:SetVertexColor(0.72,0.60,0.28,1.0)

  local classicYBase = divOffsetY - 5
  for i,extKey in ipairs(EXT_ROW2) do
    BuildExtTab(extKey, classicYBase-(i-1)*(TAB_H+TAB_GAP))
  end

  -- (Onglet Torghast supprimé de la colonne gauche - accès via onglet Tourment dans Shadowlands)

  mainFrame.extBtns = extBtns

  -- Séparateur vertical
  local sepVert = mainFrame:CreateTexture(nil,"ARTWORK")
  sepVert:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepVert:SetPoint("TOPLEFT",TAB_COL_W+13,-50)
  sepVert:SetPoint("BOTTOMLEFT",TAB_COL_W+13,12)
  sepVert:SetWidth(1)
  sepVert:SetVertexColor(0.72,0.60,0.28,0.55)

  -- ================================================================
  -- ZONE CONTENU : en-tête
  -- ================================================================
  mainFrame.extActiveLabel = mainFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
  mainFrame.extActiveLabel:SetPoint("TOPLEFT",CX,-52)
  mainFrame.extActiveLabel:SetWidth(CTW)
  mainFrame.extActiveLabel:SetJustifyH("LEFT")

  -- ================================================================
  -- ONGLETS INTERNES (Donjon / Raid / Gouffre / Tourment)
  -- Sur une seule ligne horizontale juste sous le label extension
  -- ================================================================
  local innerTabY = -72
  local innerTabW = 90
  local innerTabH = 22
  local innerTabGap = 4
  mainFrame.innerTabBtns = {}
  mainFrame.innerTabFrame = CreateFrame("Frame",nil,mainFrame)
  mainFrame.innerTabFrame:SetPoint("TOPLEFT",CX,innerTabY)
  mainFrame.innerTabFrame:SetSize(CTW, innerTabH+2)

  local function BuildInnerTab(ttype, xOff)
    local tc   = TYPE_COLORS[ttype] or {r=0.5,g=0.5,b=0.5}
    local tlbl = INNER_TAB_LABELS[ttype] or ttype
    local itb  = CreateFrame("Button",nil,mainFrame,"BackdropTemplate")
    itb:SetSize(innerTabW, innerTabH)
    itb:SetPoint("TOPLEFT", CX + xOff, innerTabY)
    itb:SetBackdrop({
      bgFile="Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      tile=true, tileSize=8, edgeSize=4,
      insets={left=1,right=1,top=1,bottom=1},
    })
    itb:SetBackdropColor(tc.r*0.12,tc.g*0.12,tc.b*0.12,0.95)
    itb:SetBackdropBorderColor(tc.r*0.40,tc.g*0.40,tc.b*0.40,0.65)
    local itTxt = itb:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    itTxt:SetPoint("CENTER",itb,"CENTER")
    itTxt:SetText(string.format("|cFF%02X%02X%02X%s|r",hex(tc.r),hex(tc.g),hex(tc.b),tlbl))
    itb.ttype = ttype
    itb.itTxt = itTxt
    itb.tc    = tc
    itb.tlbl  = tlbl
    itb:SetScript("OnClick",function(s)
      DgnTrackerDB.activeTab = s.ttype
      mainFrame:RefreshContent()
    end)
    itb:SetScript("OnEnter",function(s)
      if DgnTrackerDB.activeTab ~= s.ttype then
        s:SetBackdropBorderColor(tc.r*0.7,tc.g*0.7,tc.b*0.7,0.9)
      end
    end)
    itb:SetScript("OnLeave",function(s)
      if DgnTrackerDB.activeTab ~= s.ttype then
        s:SetBackdropBorderColor(tc.r*0.40,tc.g*0.40,tc.b*0.40,0.65)
      end
    end)
    table.insert(mainFrame.innerTabBtns, itb)
    return itb
  end

  -- Crée les boutons onglets pour TOUS les types possibles
  -- (dungeon, raid, delve, torghast) — affichés/masqués selon l'extension active
  local ALL_POSSIBLE_TABS = {"dungeon","raid","delve","torghast"}
  local ix = 0
  for _, ttype in ipairs(ALL_POSSIBLE_TABS) do
    BuildInnerTab(ttype, ix)
    ix = ix + innerTabW + innerTabGap
  end

  -- Séparateur sous les onglets internes
  local sepInner = mainFrame:CreateTexture(nil,"ARTWORK")
  sepInner:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepInner:SetPoint("TOPLEFT",CX, innerTabY - innerTabH - 2)
  sepInner:SetWidth(CTW - 4)
  sepInner:SetHeight(1)
  sepInner:SetVertexColor(0.72,0.60,0.28,0.35)

  -- ================================================================
  -- SCROLL DES INSTANCES
  -- ================================================================
  local scrollFrame = CreateFrame("ScrollFrame",nil,mainFrame,"UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT",CX, innerTabY - innerTabH - 8)
  scrollFrame:SetPoint("BOTTOMRIGHT",-28,16)
  mainFrame.scrollFrame = scrollFrame

  local scrollChild = CreateFrame("Frame",nil,scrollFrame)
  scrollChild:SetSize(CTW - 24, 1)
  scrollFrame:SetScrollChild(scrollChild)
  mainFrame.scrollChild = scrollChild
  mainFrame.instanceFrames = {}

  -- ================================================================
  -- HELPER : colorisation des textes de conseils
  -- ================================================================
  local function ColorizeAccess(txt)
    if not txt then return "" end
    txt = txt:gsub("([Pp]ortail[%s%w'éèàâêôû%-]*)", "|cFFCC88FF%1|r")
    txt = txt:gsub("([Mm]a%îtres? des [Vv]ols)", "|cFFFFAA44%1|r")
    txt = txt:gsub("([Ff]ly)", "|cFFFFAA44%1|r")
    txt = txt:gsub("([Vv]olez?%s)", "|cFF88DDFF%1|r")
    txt = txt:gsub("(Dalaran)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Shattrath)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Dornogal)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Valdrakken)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Orgrimmar)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Boralus)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Stormwind)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("(Lune%-d'Argent)", "|cFFFFFFFF%1|r")
    txt = txt:gsub("%[H%]", "|cFFFF6666[H]|r")
    txt = txt:gsub("%[A%]", "|cFFAADDFF[A]|r")
    return txt
  end

  local function ColorizePath(txt)
    if not txt then return "" end
    txt = txt:gsub("([Ee]scaliers?)", "|cFFFFCC44%1|r")
    txt = txt:gsub("([Dd]escendez?)", "|cFF88FFAA%1|r")
    txt = txt:gsub("([Mm]ontez?)", "|cFF88FFAA%1|r")
    txt = txt:gsub("([Ee]ntrez?)", "|cFF88FFAA%1|r")
    txt = txt:gsub("([Cc]herchez?)", "|cFF88FFAA%1|r")
    txt = txt:gsub("([Pp]longez?)", "|cFF88FFAA%1|r")
    txt = txt:gsub("([Nn]agez?)", "|cFF88FFAA%1|r")
    return "|cFFCCCCCC"..txt.."|r"
  end

  -- ================================================================
  -- REFRESH CONTENT
  -- ================================================================
  mainFrame.RefreshContent = function(self)
    local extKey  = DgnTrackerDB.extension or "TheWarWithin"
    local extCol  = EXT_TAB_COLORS[extKey] or {r=1,g=0.84,b=0}
    local extFull = EXT_FULLNAMES[extKey] or extKey

    -- Label extension active
    self.extActiveLabel:SetText(string.format(
      "|cFFFFD700Extension :|r  |cFF%02X%02X%02X%s|r",
      hex(extCol.r),hex(extCol.g),hex(extCol.b),extFull))

    -- ── Onglets extension (highlight + compteurs) ──────────────
    for _,eb in ipairs(self.extBtns or {}) do
      local col = eb.col or {r=0.5,g=0.5,b=0.5}
      if eb.extKey == extKey then
        eb:SetBackdropColor(col.r*0.40,col.g*0.40,col.b*0.40,1.0)
        eb:SetBackdropBorderColor(col.r,col.g,col.b,1.0)
        -- (accent supprimé)
      else
        eb:SetBackdropColor(col.r*0.12,col.g*0.12,col.b*0.12,0.95)
        eb:SetBackdropBorderColor(col.r*0.35,col.g*0.35,col.b*0.35,0.5)
        -- (accent supprimé)
      end
      if eb.cntLbl then
        local ed = DgnTrackerData[eb.extKey]
        local n = ed and ed.instances and #ed.instances or 0
        eb.cntLbl:SetText(n>0 and string.format("|cFF888888%d|r",n) or "")
      end
    end

    -- ── Onglets internes : dynamiques selon l'extension ──────────
    local tabsForExt = GetTabsForExt(extKey)
    local activeTab  = DgnTrackerDB.activeTab or "dungeon"

    -- Si l'onglet actif n'est pas dans la liste de cette ext → prendre le 1er dispo
    local activeValid = false
    for _, t in ipairs(tabsForExt) do
      if t == activeTab then activeValid = true; break end
    end
    if not activeValid and #tabsForExt > 0 then
      activeTab = tabsForExt[1]
      DgnTrackerDB.activeTab = activeTab
    end

    -- Repositionner + afficher/masquer les onglets selon la liste ordonnée
    local CX_ref = TAB_COL_W + 18
    local innerTabW = 90
    local innerTabGap = 4
    local innerTabY = -72
    local xOff = 0
    for _,itb in ipairs(self.innerTabBtns or {}) do
      -- Cherche si ce type est dans tabsForExt
      local pos = nil
      for i, t in ipairs(tabsForExt) do
        if t == itb.ttype then pos = i; break end
      end
      if pos then
        -- Recalcule la position X selon l'ordre dans tabsForExt
        local xPos = CX_ref + (pos-1) * (innerTabW + innerTabGap)
        itb:ClearAllPoints()
        itb:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xPos, innerTabY)
        -- Mise à jour du label (au cas où torghast = "Tourment")
        local tc = itb.tc
        itb:Show()
        local lbl = ALL_TAB_LABELS[itb.ttype] or itb.tlbl
        if itb.ttype == activeTab then
          itb:SetBackdropColor(tc.r*0.35,tc.g*0.35,tc.b*0.35,1.0)
          itb:SetBackdropBorderColor(tc.r,tc.g,tc.b,1.0)
          itb.itTxt:SetText(string.format("|cFFFFFFFF%s|r", lbl))
        else
          itb:SetBackdropColor(tc.r*0.08,tc.g*0.08,tc.b*0.08,0.95)
          itb:SetBackdropBorderColor(tc.r*0.35,tc.g*0.35,tc.b*0.35,0.55)
          itb.itTxt:SetText(string.format("|cFF%02X%02X%02X%s|r",
            hex(tc.r*0.7),hex(tc.g*0.7),hex(tc.b*0.7), lbl))
        end
      else
        itb:Hide()
      end
    end

    -- ── Nettoyer anciens widgets ─────────────────────────────────
    for _,f in ipairs(self.instanceFrames or {}) do f:Hide() end
    self.instanceFrames = {}

    -- ── Sélection de la liste d'instances ───────────────────────
    local instList = {}
    if extKey == "Torghast" or (extKey == "Shadowlands" and activeTab == "torghast") then
      instList = GetTorghastInstances()
    else
      local extD = DgnTrackerData[extKey]
      if extD and extD.instances then
        for _, inst in ipairs(extD.instances) do
          if inst.type == activeTab then
            table.insert(instList, inst)
          end
        end
      end
    end

    if #instList == 0 then
      self.scrollChild:SetHeight(100)
      -- Message vide
      local emptyLbl = self.scrollChild:CreateFontString(nil,"OVERLAY","GameFontNormal")
      emptyLbl:SetPoint("CENTER",self.scrollChild,"CENTER")
      emptyLbl:SetText("|cFF666666Aucune instance disponible pour cette catégorie.|r")
      table.insert(self.instanceFrames, emptyLbl)
      self:SetHeight(math.max(COL_CONTENT_H + 70, 400))
      return
    end

    -- ============================================================
    -- ACCORDION
    -- ============================================================
    local rowW   = self.scrollChild:GetWidth() - 6
    local curY   = 0
    local HEADER_H = 38
    local GAP    = 3

    if not DgnTrackerDB.expandedInst then
      DgnTrackerDB.expandedInst = {}
    end

    for _, inst in ipairs(instList) do
      local tc    = TYPE_COLORS[inst.type] or {r=0.5,g=0.5,b=0.5}
      local tlbl  = TYPE_LABELS[inst.type] or inst.type
      local isOpen= DgnTrackerDB.expandedInst[inst.name] == true

      -- ── HEADER ──────────────────────────────────────────────
      local hdr = CreateFrame("Button",nil,self.scrollChild,"BackdropTemplate")
      hdr:SetPoint("TOPLEFT",0,-curY)
      hdr:SetWidth(rowW)
      hdr:SetHeight(HEADER_H)
      hdr:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=8, edgeSize=5,
        insets={left=1,right=1,top=1,bottom=1},
      })
      if isOpen then
        hdr:SetBackdropColor(tc.r*0.18,tc.g*0.18,tc.b*0.18,0.98)
        hdr:SetBackdropBorderColor(tc.r,tc.g,tc.b,0.95)
      else
        hdr:SetBackdropColor(tc.r*0.07,tc.g*0.07,tc.b*0.07,0.95)
        hdr:SetBackdropBorderColor(tc.r*0.40,tc.g*0.40,tc.b*0.40,0.65)
      end
      table.insert(self.instanceFrames, hdr)

      -- Bouton +/- (remplace accent bar + flèche)
      local toggleBtn = hdr:CreateFontString(nil,"OVERLAY")
      toggleBtn:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE")
      toggleBtn:SetPoint("LEFT",hdr,"LEFT",8,0)
      toggleBtn:SetSize(16,16)
      if isOpen then
        toggleBtn:SetText(string.format("|cFF%02X%02X%02X-|r",hex(tc.r),hex(tc.g),hex(tc.b)))
      else
        toggleBtn:SetText(string.format("|cFF%02X%02X%02X+|r",hex(tc.r),hex(tc.g),hex(tc.b)))
      end

      -- Nom instance (directement, sans badge type)
      local nameFS = hdr:CreateFontString(nil,"OVERLAY")
      nameFS:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE")
      nameFS:SetPoint("LEFT",hdr,"LEFT",28,0)
      nameFS:SetPoint("RIGHT",hdr,"RIGHT",-90,0)
      nameFS:SetJustifyH("LEFT")
      nameFS:SetWordWrap(false)
      local nameColor = isOpen and "|cFFFFD700" or "|cFFDDCC88"
      nameFS:SetText(nameColor..inst.name.."|r")

      -- Zone + coords (droite)
      local zoneFS = hdr:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      zoneFS:SetPoint("BOTTOMRIGHT",hdr,"BOTTOMRIGHT",-8,5)
      zoneFS:SetJustifyH("RIGHT")
      if inst.coords then
        zoneFS:SetText(string.format("|cFF888888%s|r  |cFF99CCFF%.1f, %.1f|r",
          inst.zone, inst.coords.x, inst.coords.y))
      else
        zoneFS:SetText("|cFF888888"..inst.zone.."|r")
      end

      local instRef = inst
      hdr:SetScript("OnClick",function()
        DgnTrackerDB.expandedInst[instRef.name] = not DgnTrackerDB.expandedInst[instRef.name]
        mainFrame:RefreshContent()
      end)
      hdr:SetScript("OnEnter",function(s)
        if not DgnTrackerDB.expandedInst[instRef.name] then
          s:SetBackdropBorderColor(tc.r*0.7,tc.g*0.7,tc.b*0.7,0.9)
        end
        GameTooltip:SetOwner(s,"ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(instRef.name,1,0.84,0)
        GameTooltip:AddLine("Clic pour "..(DgnTrackerDB.expandedInst[instRef.name] and "fermer" or "afficher le chemin"),0.7,0.7,0.7)
        GameTooltip:Show()
      end)
      hdr:SetScript("OnLeave",function(s)
        if not DgnTrackerDB.expandedInst[instRef.name] then
          s:SetBackdropBorderColor(tc.r*0.40,tc.g*0.40,tc.b*0.40,0.65)
        end
        GameTooltip:Hide()
      end)

      curY = curY + HEADER_H + GAP

      -- ── DETAIL (déplié) ────────────────────────────────────
      if isOpen then
        local faction = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
        local accessText = ""
        if inst.access then
          if inst.access.both then accessText = inst.access.both
          elseif faction=="Alliance" and inst.access.alliance then accessText = inst.access.alliance
          elseif faction=="Horde" and inst.access.horde then accessText = inst.access.horde
          elseif inst.access.alliance then accessText = "|cFFAADDFF[A]|r "..inst.access.alliance
          elseif inst.access.horde then accessText = "|cFFFF6666[H]|r "..inst.access.horde
          end
        end
        local pathText = inst.path or ""

        local CHARS = math.floor((rowW - 30) / 7.5)
        if CHARS < 30 then CHARS = 60 end
        local function nLines(txt)
          local plain = txt:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T[^|]+|t","")
          return math.max(1, math.ceil(#plain / CHARS))
        end
        local lA = nLines(accessText)
        local lP = nLines(pathText)
        local detH = 16          -- breadcrumb région
                   + 14 + lA*15 + 8   -- accès
                   + 14 + lP*15 + 14  -- conseils + padding bas

        local det = CreateFrame("Frame",nil,self.scrollChild,"BackdropTemplate")
        det:SetPoint("TOPLEFT",0,-curY)
        det:SetWidth(rowW)
        det:SetHeight(detH)
        det:SetBackdrop({
          bgFile="Interface\\ChatFrame\\ChatFrameBackground",
          edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
          tile=true, tileSize=8, edgeSize=5,
          insets={left=1,right=1,top=1,bottom=1},
        })
        det:SetBackdropColor(tc.r*0.05,tc.g*0.05,tc.b*0.05,0.97)
        det:SetBackdropBorderColor(tc.r*0.60,tc.g*0.60,tc.b*0.60,0.7)
        table.insert(self.instanceFrames, det)

        local iX,iY = 14,-6

        -- ── Fil d'Ariane : Région > Zone > Nom ──────────────────
        local extFull2 = EXT_FULLNAMES[extKey] or extKey
        local breadcrumb = ""
        -- Construit le fil d'Ariane avec les niveaux disponibles
        -- Format : Extension > Région > Secteur > Zone > Nom
        local parts = {}
        table.insert(parts, string.format("|cFF666666%s|r", extFull2))
        if inst.region and inst.region ~= "" then
          table.insert(parts, string.format("|cFFAA8855%s|r", inst.region))
        end
        if inst.sector and inst.sector ~= "" and inst.sector ~= inst.region then
          table.insert(parts, string.format("|cFFCC9944%s|r", inst.sector))
        end
        if inst.zone and inst.zone ~= "" then
          table.insert(parts, string.format("|cFF99CCFF%s|r", inst.zone))
        end
        table.insert(parts, string.format("|cFFDDCC88%s|r", inst.name))
        -- Séparateur ">"
        breadcrumb = table.concat(parts, " |cFF555555>|r ")
        local fsBC = det:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fsBC:SetPoint("TOPLEFT",det,"TOPLEFT",iX,iY)
        fsBC:SetPoint("TOPRIGHT",det,"TOPRIGHT",-8,iY)
        fsBC:SetHeight(14)
        fsBC:SetJustifyH("LEFT")
        fsBC:SetWordWrap(false)
        fsBC:SetText(breadcrumb)
        iY = iY - 18

        -- ── Accès ────────────────────────────────────────────────
        local lbA = det:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lbA:SetPoint("TOPLEFT",det,"TOPLEFT",iX,iY)
        lbA:SetText(string.format("|cFF%02X%02X%02X-- Accès (chemin le plus court) :|r",
          hex(tc.r),hex(tc.g),hex(tc.b)))
        iY = iY - 15
        local fsA = det:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fsA:SetPoint("TOPLEFT",det,"TOPLEFT",iX+6,iY)
        fsA:SetPoint("TOPRIGHT",det,"TOPRIGHT",-14,iY)
        fsA:SetHeight(lA*15+4)
        fsA:SetJustifyH("LEFT")
        fsA:SetWordWrap(true)
        fsA:SetText(ColorizeAccess(accessText))
        iY = iY - lA*15 - 8

        -- ── Conseils ─────────────────────────────────────────────
        local lbP = det:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lbP:SetPoint("TOPLEFT",det,"TOPLEFT",iX,iY)
        lbP:SetText(string.format("|cFF%02X%02X%02X-- Conseils :|r",
          hex(tc.r),hex(tc.g),hex(tc.b)))
        iY = iY - 15
        local fsP = det:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fsP:SetPoint("TOPLEFT",det,"TOPLEFT",iX+6,iY)
        fsP:SetPoint("TOPRIGHT",det,"TOPRIGHT",-14,iY)
        fsP:SetHeight(lP*15+4)
        fsP:SetJustifyH("LEFT")
        fsP:SetWordWrap(true)
        fsP:SetText(ColorizePath(pathText))

        curY = curY + detH + GAP
      end
    end

    self.scrollChild:SetHeight(math.max(curY + 10, 100))

    -- Auto-resize fenêtre
    local newH = math.max(COL_CONTENT_H + 70, math.min(curY + 200, 900), 400)
    self:SetHeight(newH)
    -- Ajuste la hauteur du tabColBg pour coller à la fenêtre
    if self.tabColBg then
      self.tabColBg:SetHeight(newH - 64)
    end
  end

  mainFrame:Hide()
end

-- ================================================================
-- BOUTON MINIMAP
-- ================================================================
local minimapBtn

local function GetMinimapRadius()
  return (Minimap:GetWidth()/2) + 10
end

local function SetMinimapPos(angle)
  angle = angle % 360
  if DgnTrackerDB then DgnTrackerDB.mmAngle = angle end
  local r   = GetMinimapRadius()
  local rad = math.rad(angle)
  minimapBtn:ClearAllPoints()
  minimapBtn:SetPoint("CENTER",Minimap,"CENTER",math.cos(rad)*r,math.sin(rad)*r)
end

local function BuildMinimapButton()
  minimapBtn = CreateFrame("Button","DTMinimapBtn",Minimap)
  minimapBtn:SetSize(32,32)
  minimapBtn:SetFrameStrata("MEDIUM")
  minimapBtn:SetFrameLevel(8)
  minimapBtn:EnableMouse(true)
  minimapBtn:SetClampedToScreen(true)
  minimapBtn:SetToplevel(true)

  local icon = minimapBtn:CreateTexture(nil,"ARTWORK")
  icon:SetPoint("CENTER",0,0)
  icon:SetSize(24,24)
  icon:SetTexture("Interface\\AddOns\\DgnTracker\\medias\\DgnTracker")
  local mask = minimapBtn:CreateMaskTexture()
  mask:SetAllPoints(icon)
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
    "CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
  icon:AddMaskTexture(mask)

  local ring = minimapBtn:CreateTexture(nil,"OVERLAY")
  ring:SetSize(52,52)
  ring:SetPoint("TOPLEFT",minimapBtn,"TOPLEFT",0,0)
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  local hl = minimapBtn:CreateTexture(nil,"ARTWORK")
  hl:SetPoint("CENTER",0,0)
  hl:SetSize(20,20)
  hl:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  hl:SetVertexColor(1,1,1,0.25)
  hl:SetAlpha(0)
  minimapBtn._hl = hl

  SetMinimapPos((DgnTrackerDB and DgnTrackerDB.mmAngle) or 195)
  minimapBtn:SetScript("OnShow",function()
    SetMinimapPos((DgnTrackerDB and DgnTrackerDB.mmAngle) or 195)
  end)
  minimapBtn:RegisterForDrag("LeftButton")
  minimapBtn:SetScript("OnDragStart",function(s)
    s:SetScript("OnUpdate",function()
      local mx,my = Minimap:GetCenter()
      local sc = UIParent:GetEffectiveScale()
      local cx,cy = GetCursorPosition()
      SetMinimapPos(math.deg(math.atan2((cy/sc)-my,(cx/sc)-mx)))
    end)
  end)
  minimapBtn:SetScript("OnDragStop",function(s) s:SetScript("OnUpdate",nil) end)

  local rw = CreateFrame("Frame")
  rw:RegisterEvent("MINIMAP_UPDATE_ZOOM")
  rw:SetScript("OnEvent",function()
    SetMinimapPos((DgnTrackerDB and DgnTrackerDB.mmAngle) or 195)
  end)

  minimapBtn:SetScript("OnClick",function(_,btn)
    if btn=="LeftButton" then
      if mainFrame:IsShown() then
        mainFrame:Hide(); DgnTrackerDB.open=false
      else
        mainFrame:Show(); mainFrame:RefreshContent(); DgnTrackerDB.open=true
      end
    end
  end)
  minimapBtn:SetScript("OnEnter",function(s)
    if s._hl then s._hl:SetAlpha(1) end
    GameTooltip:SetOwner(s,"ANCHOR_LEFT")
    GameTooltip:AddLine("|cFF0070DEDgnTracker|r",0.30,0.70,1.0)
    GameTooltip:AddLine("Tracker des instances & raids",0.9,0.9,0.9)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFFFFD700Clic gauche|r : ouvrir / fermer",0.7,0.7,0.7)
    GameTooltip:AddLine("|cFFFFD700Glisser|r : repositionner l'icône",0.7,0.7,0.7)
    GameTooltip:Show()
  end)
  minimapBtn:SetScript("OnLeave",function(s)
    if s._hl then s._hl:SetAlpha(0) end
    GameTooltip:Hide()
  end)
end

-- ================================================================
-- ADDON COMPARTMENT
-- ================================================================
function DgnTracker_OnAddonCompartmentClick()
  if mainFrame:IsShown() then
    mainFrame:Hide(); DgnTrackerDB.open=false
  else
    mainFrame:Show(); mainFrame:RefreshContent(); DgnTrackerDB.open=true
  end
end
function DgnTracker_OnAddonCompartmentEnter(btn)
  GameTooltip:SetOwner(btn,"ANCHOR_LEFT")
  GameTooltip:AddLine("DgnTracker",0.30,0.70,1.0)
  GameTooltip:AddLine("Tracker des instances & raids",0.9,0.9,0.9)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("|cFFFFD700Clic|r : ouvrir / fermer",0.7,0.7,0.7)
  GameTooltip:Show()
end
function DgnTracker_OnAddonCompartmentLeave() GameTooltip:Hide() end

-- ================================================================
-- COMMANDES SLASH
-- ================================================================
SLASH_DGNTRACKER1 = "/tdg"
SLASH_DGNTRACKER2 = "/tibidgn"
SlashCmdList["DGNTRACKER"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s*(.-)%s*$","%1")
  if msg=="help" or msg=="aide" then
    print("|cFF4D99FFDgnTracker|r commandes :")
    print("  |cFFFFD700/tdg|r         - Ouvrir/fermer la fenêtre")
    print("  |cFFFFD700/tdg map on|r  - Activer les pins carte")
    print("  |cFFFFD700/tdg map off|r - Désactiver les pins carte")
    print("  |cFFFFD700/tdg reset|r   - Tout replier (accordéon)")
    return
  elseif msg=="reset" then
    DgnTrackerDB.expandedInst = {}
    if mainFrame:IsShown() then mainFrame:RefreshContent() end
    print("|cFF4D99FFDgnTracker|r : Accordéon réinitialisé.")
    return
  end
  if mainFrame:IsShown() then
    mainFrame:Hide(); DgnTrackerDB.open=false
  else
    mainFrame:Show(); mainFrame:RefreshContent(); DgnTrackerDB.open=true
  end
end

-- ================================================================
-- EVENEMENTS
-- ================================================================
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:SetScript("OnEvent",function(_,event,arg1)
  if event=="ADDON_LOADED" and arg1==ADDON then
    -- S'assure que l'onglet par défaut est "donjon"
    DgnTrackerDB.activeTab = DgnTrackerDB.activeTab or "dungeon"
    DgnTrackerDB.expandedInst = DgnTrackerDB.expandedInst or {}
    BuildUI()
    BuildMinimapButton()
    local p = DgnTrackerDB.pos
    if p and p.x then
      mainFrame:ClearAllPoints()
      mainFrame:SetPoint(p.point or "CENTER",UIParent,p.point or "CENTER",p.x,p.y)
    else
      mainFrame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    end
    if DgnTrackerDB.open then
      mainFrame:Show()
      if mainFrame.RefreshContent then mainFrame:RefreshContent() end
    end
  elseif event=="PLAYER_LOGIN" then
    print("|cFF4D99FFDgnTracker|r v1.3 chargé -- |cFFFFD700/tdg|r pour ouvrir.")
  end
end)
