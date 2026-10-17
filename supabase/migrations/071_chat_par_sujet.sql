-- 071 · Un sommelier par vin, par carte (V2.5 · F4), et « Effacer » qui efface vraiment.
--
-- Le 13/10, Flavien, depuis la fiche d'un crozes-hermitage : « à chaque fois qu'on ouvre le
-- Chatmelier à partir d'un vin, d'un menu, etc... ça devrait spin une nouvelle instance du
-- Chatmelier dédiée à cet item, avec son propre historique ». Une conversation a désormais
-- un sujet : aucun pour le chat général, « vin:<id du vin> » ou « carte:<id de la carte> ».
-- L'app et la fonction `chat` ne lisent l'historique que d'un sujet à la fois.
--
-- Vu en chemin, dans pg_catalog de la production (17/10) : aucune règle ne permet de
-- supprimer ses messages. « Effacer la conversation » ne supprimait donc rien, et le
-- sommelier relisait la conversation « effacée » à la question suivante. Chacun peut
-- désormais supprimer les siens. La lecture reste celle de la production : ses seuls
-- messages (002 et 006 laissaient lire ceux des autres membres de la cave ; la production
-- ne le permet plus, et le dépôt s'y aligne).
--
-- Vérification :
--   SELECT polname, polcmd FROM pg_policy WHERE polrelid = 'public.chat_messages'::regclass;
--   SELECT attname FROM pg_attribute WHERE attrelid = 'public.chat_messages'::regclass AND attname = 'sujet';

ALTER TABLE public.chat_messages ADD COLUMN IF NOT EXISTS sujet TEXT;

ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sujet_forme;
ALTER TABLE public.chat_messages ADD CONSTRAINT chat_messages_sujet_forme
  CHECK (sujet IS NULL OR sujet ~ '^(vin|carte):[A-Za-z0-9_-]{1,100}$');

-- Une conversation : une personne, une cave, un sujet, dans l'ordre.
CREATE INDEX IF NOT EXISTS chat_messages_conversation_idx
  ON public.chat_messages (user_id, cellar_id, sujet, created_at DESC);

DROP POLICY IF EXISTS "Members can view chat messages." ON public.chat_messages;
DROP POLICY IF EXISTS "Users can only view their own chat messages." ON public.chat_messages;
CREATE POLICY "Users can only view their own chat messages." ON public.chat_messages
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own chat messages." ON public.chat_messages;
CREATE POLICY "Users can delete their own chat messages." ON public.chat_messages
  FOR DELETE USING (user_id = auth.uid());
