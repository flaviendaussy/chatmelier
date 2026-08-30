ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cellars ENABLE ROW LEVEL SECURITY;
ALTER TABLE cellar_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE wines ENABLE ROW LEVEL SECURITY;
ALTER TABLE bottles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bottle_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasting_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- cellars
CREATE POLICY "Users can view cellars they are members of." ON cellars FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = cellars.id AND user_id = auth.uid())
);
CREATE POLICY "Users can create cellars." ON cellars FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Owners can update their cellars." ON cellars FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Owners can delete their cellars." ON cellars FOR DELETE USING (owner_id = auth.uid());

-- cellar_members
CREATE POLICY "Members can view cellar members." ON cellar_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members cm WHERE cm.cellar_id = cellar_members.cellar_id AND cm.user_id = auth.uid())
);
CREATE POLICY "Admins can manage cellar members." ON cellar_members FOR ALL USING (
  EXISTS (SELECT 1 FROM cellar_members cm WHERE cm.cellar_id = cellar_members.cellar_id AND cm.user_id = auth.uid() AND cm.role = 'admin')
);

-- wines
CREATE POLICY "Wines are viewable by everyone." ON wines FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create wines." ON wines FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update wines." ON wines FOR UPDATE USING (auth.role() = 'authenticated');

-- bottles
CREATE POLICY "Members can view bottles in their cellars." ON bottles FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid())
);
CREATE POLICY "Editors and admins can insert bottles." ON bottles FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);
CREATE POLICY "Editors and admins can update bottles." ON bottles FOR UPDATE USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);
CREATE POLICY "Editors and admins can delete bottles." ON bottles FOR DELETE USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);

-- bottle_photos
CREATE POLICY "Members can view bottle photos." ON bottle_photos FOR SELECT USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid())
);
CREATE POLICY "Editors and admins can insert photos." ON bottle_photos FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);
CREATE POLICY "Editors and admins can update photos." ON bottle_photos FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);
CREATE POLICY "Editors and admins can delete photos." ON bottle_photos FOR DELETE USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);

-- tasting_log
CREATE POLICY "Members can view tasting logs." ON tasting_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = tasting_log.cellar_id AND user_id = auth.uid())
);
CREATE POLICY "Users can create their own tasting logs." ON tasting_log FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update their own tasting logs." ON tasting_log FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete their own tasting logs." ON tasting_log FOR DELETE USING (user_id = auth.uid());

-- chat_messages
CREATE POLICY "Members can view chat messages." ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = chat_messages.cellar_id AND user_id = auth.uid())
);
CREATE POLICY "Members can insert chat messages." ON chat_messages FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = chat_messages.cellar_id AND user_id = auth.uid())
);