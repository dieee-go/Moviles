-- Create Carrera table (Career catalog)
CREATE TABLE IF NOT EXISTS public.carreras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Departamento table (Department catalog)
CREATE TABLE IF NOT EXISTS public.departamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create junction table: user_carrera
CREATE TABLE IF NOT EXISTS public.user_carrera (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  carrera_id UUID NOT NULL REFERENCES public.carreras(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, carrera_id)
);

-- Create junction table: user_departamento
CREATE TABLE IF NOT EXISTS public.user_departamento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  departamento_id UUID NOT NULL REFERENCES public.departamentos(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, departamento_id)
);

-- Insert Carreras
INSERT INTO public.carreras (name) VALUES
  ('Ingeniería en Sistemas Computacionales'),
  ('Licenciatura en Ciencia de Datos'),
  ('Ingeniería en Inteligencia Artificial')
ON CONFLICT (name) DO NOTHING;

-- Insert Departamentos
INSERT INTO public.departamentos (name) VALUES
  ('Departamento de Formación Básica'),
  ('Departamento de Ciencias e Ingeniería de la Computación'),
  ('Departamento de Ingeniería en Sistemas Computacionales'),
  ('Departamento de Posgrado'),
  ('Departamento de Investigación'),
  ('Departamento de Innovación Educativa'),
  ('Unidad de Tecnología Educativa y Campus Virtual'),
  ('Comité Interno de Proyectos'),
  ('Subdirección de Servicios Educativos e Integración Social'),
  ('Departamento de Servicios Estudiantiles'),
  ('Departamento de Extensión y Apoyos Educativos'),
  ('Unidad Politécnica de Integración Social'),
  ('Coordinación de Enlace y Gestión Técnica')
ON CONFLICT (name) DO NOTHING;

-- Enable RLS on carreras table
ALTER TABLE public.carreras ENABLE ROW LEVEL SECURITY;

-- Enable RLS on departamentos table
ALTER TABLE public.departamentos ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_carrera table
ALTER TABLE public.user_carrera ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_departamento table
ALTER TABLE public.user_departamento ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Everyone can read carreras (public catalog)
CREATE POLICY "Anyone can read carreras" ON public.carreras
  FOR SELECT USING (true);

-- RLS Policy: Everyone can read departamentos (public catalog)
CREATE POLICY "Anyone can read departamentos" ON public.departamentos
  FOR SELECT USING (true);

-- RLS Policy: Users can read their own user_carrera
CREATE POLICY "Users can read own user_carrera" ON public.user_carrera
  FOR SELECT USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own user_carrera
CREATE POLICY "Users can insert own user_carrera" ON public.user_carrera
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own user_carrera
CREATE POLICY "Users can update own user_carrera" ON public.user_carrera
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own user_carrera
CREATE POLICY "Users can delete own user_carrera" ON public.user_carrera
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policy: Users can read their own user_departamento
CREATE POLICY "Users can read own user_departamento" ON public.user_departamento
  FOR SELECT USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own user_departamento
CREATE POLICY "Users can insert own user_departamento" ON public.user_departamento
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own user_departamento
CREATE POLICY "Users can update own user_departamento" ON public.user_departamento
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own user_departamento
CREATE POLICY "Users can delete own user_departamento" ON public.user_departamento
  FOR DELETE USING (auth.uid() = user_id);
