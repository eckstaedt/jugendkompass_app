
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { 
  BarChart2Icon, 
  CalendarIcon, 
  FileTextIcon, 
  PieChartIcon, 
  FileVideoIcon, 
  UsersIcon,
  LogOut,
  Moon,
  Sun,
  Globe
} from 'lucide-react';
import { useTheme } from '@/hooks/use-theme';
import { useEffect } from 'react';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

interface SidebarProps {
  collapsed?: boolean;
}

type NavItem = {
  label: string;
  path: string;
  icon: React.ElementType;
  subItems?: Array<{ label: string; path: string }>;
};

export const Sidebar = ({ collapsed = false }: SidebarProps) => {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { theme, toggleTheme } = useTheme();
  const { previewLang, setPreviewLang } = usePreviewLocale();
  
  const navItems: NavItem[] = [
    {
      label: 'Dashboard',
      path: '/dashboard',
      icon: BarChart2Icon,
    },
    {
      label: 'Aktueller Feed',
      path: '/dashboard/feed',
      icon: FileTextIcon,
    },
    {
      label: 'Beiträge',
      path: '/dashboard/posts',
      icon: FileTextIcon,
      subItems: [
        { label: 'Alle Beiträge', path: '/dashboard/posts' },
        { label: 'Neuer Beitrag', path: '/dashboard/posts/new' },
        { label: 'Kategorien', path: '/dashboard/posts/categories' },
        { label: 'Ausgaben', path: '/dashboard/posts/ausgaben' },
      ],
    },
    {
      label: 'Umfragen',
      path: '/dashboard/polls',
      icon: PieChartIcon,
      subItems: [
        { label: 'Alle Umfragen', path: '/dashboard/polls' },
        { label: 'Neue Umfrage', path: '/dashboard/polls/new' },
      ],
    },
    {
      label: 'Videos',
      path: '/dashboard/videos',
      icon: FileVideoIcon,
      subItems: [
        { label: 'Alle Videos', path: '/dashboard/videos' },
        { label: 'Neues Video', path: '/dashboard/videos/new' },
      ],
    },
    {
      label: 'Vers des Tages',
      path: '/dashboard/daily-verses',
      icon: CalendarIcon,
      subItems: [
        { label: 'Alle Verse', path: '/dashboard/daily-verses' },
        { label: 'Neuer Vers', path: '/dashboard/daily-verses/new' },
      ],
    },
    {
      label: 'Impulse',
      path: '/dashboard/impulses',
      icon: FileTextIcon,
    },
    {
      label: 'Kurznachrichten',
      path: '/dashboard/messages',
      icon: FileTextIcon,
    },
    {
      label: 'Benutzer',
      path: '/dashboard/users',
      icon: UsersIcon,
    },
  ];
  
  const isActive = (path: string) => {
    if (path === '/dashboard') {
      return location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(path) && path !== '/dashboard';
  };
  
  const handleNavigation = (path: string) => {
    navigate(path);
  };

  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark');
  }, [theme]);

  return (
    <div className={cn(
      "flex h-full flex-col border-r bg-sidebar text-sidebar-foreground",
      collapsed ? "items-center py-4" : "w-64 p-4"
    )}>
      <div className={cn(
        "flex items-center h-16",
        collapsed ? "justify-center pb-4" : "mb-6 pl-2"
      )}>
        {!collapsed ? (
          <div className="flex items-center">
            <img
              src="/lovable-uploads/df7fceef-ebc5-46a5-aff3-fbe34d02dc9d.png"
              alt="App Logo"
              className="h-8 w-8"
              style={{ borderRadius: '0.25rem', background: 'none' }}
            />
            <h1 className="ml-2 text-xl font-bold">Jugendkompass</h1>
          </div>
        ) : (
          <img
            src="/lovable-uploads/df7fceef-ebc5-46a5-aff3-fbe34d02dc9d.png"
            alt="App Logo"
            className="h-8 w-8"
            style={{ borderRadius: '0.25rem', background: 'none' }}
          />
        )}
      </div>
      
      <nav className="flex-1 space-y-1">
        {navItems.map((item) => {
          const active = isActive(item.path);
          return (
            <div key={item.path} className="mb-2">
              <Button
                variant={active ? "secondary" : "ghost"}
                className={cn(
                  "w-full justify-start",
                  active ? "bg-sidebar-accent text-sidebar-accent-foreground" : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                  collapsed ? "h-10 w-10 p-0 flex items-center justify-center" : "px-3 py-2"
                )}
                onClick={() => handleNavigation(item.path)}
              >
                <item.icon className={cn("h-5 w-5", active ? "text-sidebar-primary" : "")} />
                {!collapsed && <span className="ml-3">{item.label}</span>}
              </Button>
              {!collapsed && item.subItems && active && (
                <div className="mt-1 ml-9 space-y-1">
                  {item.subItems.map((subItem) => (
                    <Button
                      key={subItem.path}
                      variant="ghost"
                      className={cn(
                        "w-full justify-start px-3 py-1.5 text-sm",
                        isActive(subItem.path)
                          ? "bg-sidebar-accent/50 text-sidebar-primary font-medium"
                          : "text-sidebar-foreground hover:bg-sidebar-accent/50 hover:text-sidebar-primary"
                      )}
                      onClick={() => handleNavigation(subItem.path)}
                    >
                      {subItem.label}
                    </Button>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </nav>
      
      <div className={cn(
        "mt-auto pt-4 border-t border-sidebar-border flex flex-col gap-2",
        collapsed ? "w-full items-center" : ""
      )}>
        <Button
          variant="ghost"
          className={cn(
            "w-full justify-start text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground mb-2",
            collapsed ? "h-10 w-10 p-0 flex items-center justify-center" : "px-3 py-2"
          )}
          aria-label="Dark Mode umschalten"
          onClick={toggleTheme}
        >
          {theme === "dark" ? (
            <Sun className="h-5 w-5 text-yellow-500" />
          ) : (
            <Moon className="h-5 w-5 text-gray-700" />
          )}
          {!collapsed && <span className="ml-3">{theme === "dark" ? "Helles Design" : "Dunkles Design"}</span>}
        </Button>
        <Button
          variant="ghost"
          className={cn(
            "w-full justify-start text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
            collapsed ? "h-10 w-10 p-0 flex items-center justify-center" : "px-3 py-2"
          )}
          onClick={logout}
        >
          <LogOut className="h-5 w-5" />
          {!collapsed && <span className="ml-3">Abmelden</span>}
        </Button>
      </div>
    </div>
  );
};
