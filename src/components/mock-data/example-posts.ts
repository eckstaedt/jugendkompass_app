
// Mock-Daten für Beiträge
export const mockPosts = [
  {
    id: '1',
    title: 'Gottes Plan für dein Leben',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    category: 'Glaube',
    edition_id: '1',
    edition_name: 'Jugendkompass 1/2023',
    author_id: '1',
    created_at: '2023-01-15T10:30:00',
    updated_at: '2023-01-16T08:45:00',
    published: true,
    image_url: 'https://images.unsplash.com/photo-1504805572947-34fad45aed93?auto=format&fit=crop&w=800&q=80'
  },
  {
    id: '2',
    title: 'Wie du deinen Glauben im Alltag leben kannst',
    content: 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    category: 'Praxis',
    edition_id: '1',
    edition_name: 'Jugendkompass 1/2023',
    author_id: '2',
    created_at: '2023-01-20T14:45:00',
    updated_at: '2023-01-21T09:30:00',
    published: true,
    image_url: 'https://images.unsplash.com/photo-1493836512294-502baa1986e2?auto=format&fit=crop&w=800&q=80'
  },
  {
    id: '3',
    title: 'Die Kraft des Gebets',
    content: 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
    category: 'Glaube',
    edition_id: '2',
    edition_name: 'Jugendkompass 2/2023',
    author_id: '1',
    created_at: '2023-04-10T09:15:00',
    updated_at: '2023-04-12T11:20:00',
    published: true,
    image_url: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?auto=format&fit=crop&w=800&q=80'
  },
  {
    id: '4',
    title: 'Gemeinschaft unter Christen',
    content: 'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
    category: 'Gemeinschaft',
    edition_id: '2',
    edition_name: 'Jugendkompass 2/2023',
    author_id: '3',
    created_at: '2023-04-18T16:20:00',
    updated_at: '2023-04-19T10:15:00',
    published: false,
    image_url: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80'
  },
  {
    id: '5',
    title: 'Bibelstudium für Anfänger',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    category: 'Bibel',
    edition_id: '3',
    edition_name: 'Jugendkompass 3/2023',
    author_id: '2',
    created_at: '2023-07-05T11:10:00',
    updated_at: '2023-07-07T14:25:00',
    published: true,
    image_url: 'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?auto=format&fit=crop&w=800&q=80'
  },
];

// Mock-Daten für Editionen
export const mockEditions = [
  {
    id: '1',
    name: 'Jugendkompass 1/2023',
    year: 2023,
    description: 'Die erste Ausgabe des Jahres 2023',
    created_at: '2023-01-01T00:00:00'
  },
  {
    id: '2',
    name: 'Jugendkompass 2/2023',
    year: 2023,
    description: 'Die zweite Ausgabe des Jahres 2023',
    created_at: '2023-04-01T00:00:00'
  },
  {
    id: '3',
    name: 'Jugendkompass 3/2023',
    year: 2023,
    description: 'Die dritte Ausgabe des Jahres 2023',
    created_at: '2023-07-01T00:00:00'
  },
  {
    id: '4',
    name: 'Jugendkompass 4/2023',
    year: 2023,
    description: 'Die vierte Ausgabe des Jahres 2023',
    created_at: '2023-10-01T00:00:00'
  }
];

// Mock-Daten für Kategorien
export const mockCategories = [
  {
    id: '1',
    name: 'Glaube',
    description: 'Beiträge zum Thema Glaube und Spiritualität'
  },
  {
    id: '2',
    name: 'Bibel',
    description: 'Bibelstudien und Auslegungen'
  },
  {
    id: '3',
    name: 'Praxis',
    description: 'Praktische Anwendungen des Glaubens im Alltag'
  },
  {
    id: '4',
    name: 'Gemeinschaft',
    description: 'Beiträge zum Thema Gemeinschaft und Gemeinde'
  },
  {
    id: '5',
    name: 'Zeugnis',
    description: 'Persönliche Zeugnisse und Erfahrungen'
  }
];

// Mock-Daten für Benutzer
export const mockUsers = [
  {
    id: '1',
    email: 'admin@jugendkompass.de',
    role: 'admin',
    created_at: '2022-12-01T00:00:00'
  },
  {
    id: '2',
    email: 'autor1@jugendkompass.de',
    role: 'autor',
    created_at: '2023-01-05T00:00:00'
  },
  {
    id: '3',
    email: 'autor2@jugendkompass.de',
    role: 'autor',
    created_at: '2023-02-10T00:00:00'
  }
];
