-- Allô Vino — données de démo (lot 1)
-- Appellation, domaines et cuvées FICTIFS, provisoires : à remplacer par les 5 domaines et
-- 7 cuvées de glou-prototype.html dès que le prototype est dans le dépôt.
-- Pas de média (audio ou vidéo) ni de compte ici : ils arrivent aux lots 2 à 4.

insert into public.appellations (id, slug, name, kind, organisme, region, bio, mots, color_1, color_2, status) values
  ('a0000000-0000-4000-a000-000000000001', 'coteaux-de-la-veze', 'Coteaux de la Vèze', 'aop',
   'ODG des Coteaux de la Vèze (démo)', 'Languedoc',
   'Des collines de schiste entre garrigue et rivière. Une quarantaine de familles y font du vin.',
   array['Schiste', 'Soleil', 'Garrigue'], '#FF8FAB', '#FFC79E', 'active');

insert into public.domaines (id, slug, name, first_name, region, bio, color_1, color_2, sales_enabled, status) values
  ('d0000000-0000-4000-a000-000000000001', 'mas-des-cigales', 'Mas des Cigales', 'Léa', 'Languedoc',
   'J''ai repris les vignes de mon grand-père en 2018. Je travaille en bio, à la main.', '#FF8FAB', '#FFC79E', true, 'active'),
  ('d0000000-0000-4000-a000-000000000002', 'domaine-pierre-plate', 'Domaine Pierre Plate', 'Karim', 'Languedoc',
   'Dix hectares sur le schiste. On vendange tôt le matin pour garder la fraîcheur.', '#B8A1FF', '#FFD6E0', true, 'active'),
  ('d0000000-0000-4000-a000-000000000003', 'clos-des-amandiers', 'Clos des Amandiers', 'Margaux', 'Languedoc',
   'Petit domaine familial, trois cuvées, beaucoup de patience.', '#7FD6B0', '#FFE58F', false, 'active'),
  ('d0000000-0000-4000-a000-000000000004', 'les-terrasses-de-jo', 'Les Terrasses de Jo', 'Jo', 'Languedoc',
   'Des vignes en terrasses qu''on entretient comme un jardin.', '#FFB36B', '#FF8FAB', true, 'active'),
  ('d0000000-0000-4000-a000-000000000005', 'domaine-du-vieux-pont', 'Domaine du Vieux Pont', 'Camille', 'Languedoc',
   'Au bord de la rivière depuis quatre générations. On fait aussi des bulles.', '#8FC8FF', '#C9B8FF', false, 'active');

insert into public.appellation_domaines (appellation_id, domaine_id, status, invited_by_odg)
select 'a0000000-0000-4000-a000-000000000001', id, 'active', true from public.domaines
where id::text like 'd0000000-0000-4000-a000-00000000000%';

insert into public.wines (domaine_id, appellation_id, slug, name, color, vintage, grapes, abv, price_cents, stock, mots, tags, pairings, label_style, is_published) values
  ('d0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001', 'cigales-rouge-2023',
   'Chant des Cigales', 'rouge', 2023, 'Grenache, Syrah', 13.5, 1250, 120,
   array['Fruité', 'Gourmand', 'Souple'], array['pizza'], 'Pizza, burger, plat du quotidien',
   '{"bg":"#FF8FAB","ink":"#2A1033","motif":"waves"}', true),
  ('d0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001', 'cigales-rose-2024',
   'Rosé de Léa', 'rose', 2024, 'Cinsault, Grenache', 12.5, 1090, 200,
   array['Léger', 'Agrume', 'Se boit frais'], array['apero', 'frais', 'petitprix'], 'Salades, grillades, apéro',
   '{"bg":"#FFE3EA","ink":"#FF3D6E","motif":"dots"}', true),
  ('d0000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001', 'pierre-plate-2022',
   'Schiste', 'rouge', 2022, 'Syrah, Mourvèdre', 14.0, 1850, 60,
   array['Intense', 'Épicé', 'Profond'], array[]::text[], 'Viande rouge, plats mijotés',
   '{"bg":"#2A1033","ink":"#FFC93C","motif":"lines"}', true),
  ('d0000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001', 'amandiers-blanc-2024',
   'Fleur d''Amandier', 'blanc', 2024, 'Roussanne, Vermentino', 12.5, 1400, 80,
   array['Floral', 'Frais', 'Rond'], array['apero', 'frais'], 'Poisson, fromage de chèvre',
   '{"bg":"#FFF6D6","ink":"#24102C","motif":"flower"}', true),
  ('d0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001', 'terrasses-orange-2023',
   'Macération', 'orange', 2023, 'Grenache blanc', 12.0, 1600, 40,
   array['Surprenant', 'Sec', 'Abricot'], array[]::text[], 'Cuisine épicée, curry, tajine',
   '{"bg":"#FFB36B","ink":"#24102C","motif":"sun"}', true),
  ('d0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001', 'terrasses-rouge-2024',
   'Petit Jo', 'rouge', 2024, 'Carignan', 12.5, 950, 150,
   array['Léger', 'Fruits rouges', 'Se boit frais'], array['pizza', 'frais', 'petitprix'], 'Pizza, charcuterie',
   '{"bg":"#FF3D6E","ink":"#FFFFFF","motif":"dots"}', true),
  ('d0000000-0000-4000-a000-000000000005', 'a0000000-0000-4000-a000-000000000001', 'vieux-pont-bulles',
   'Les Bulles du Pont', 'bulles', null, 'Chardonnay, Mauzac', 12.0, 1500, 90,
   array['Pétillant', 'Pomme', 'Vif'], array['apero', 'bulles', 'frais'], 'Apéro, huîtres, dessert aux fruits',
   '{"bg":"#C9B8FF","ink":"#2A1033","motif":"bubbles"}', true);
