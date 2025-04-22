import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { 
  BookIcon, 
  BarChart2Icon, 
  BellIcon, 
  CalendarIcon, 
  FileTextIcon, 
  PieChartIcon, 
  FileVideoIcon, 
  UsersIcon, 
  SettingsIcon,
  LogOutIcon
} from 'lucide-react';

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
  
  const navItems: NavItem[] = [
    {
      label: 'Dashboard',
      path: '/dashboard',
      icon: BarChart2Icon,
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
      label: 'Benutzer',
      path: '/dashboard/users',
      icon: UsersIcon,
    },
    {
      label: 'Benachrichtigungen',
      path: '/dashboard/notifications',
      icon: BellIcon,
      subItems: [
        { label: 'Alle Benachrichtigungen', path: '/dashboard/notifications' },
        { label: 'Neue Benachrichtigung', path: '/dashboard/notifications/new' },
      ],
    },
    {
      label: 'Einstellungen',
      path: '/dashboard/settings',
      icon: SettingsIcon,
    },
  ];
  
  const isActive = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(`${path}/`);
  };
  
  const handleNavigation = (path: string) => {
    navigate(path);
  };
  
  return (
    <div className={cn(
      "flex h-full flex-col border-r bg-sidebar text-sidebar-foreground",
      collapsed ? "items-center py-4" : "w-64 p-4"
    )}>
      {/* Logo und Titelbereich */}
      <div className={cn(
        "flex items-center",
        collapsed ? "justify-center pb-4" : "mb-6 pl-2"
      )}>
        {!collapsed ? (
          <div className="flex items-center">
            <BookIcon className="h-6 w-6 text-sidebar-primary" />
            <h1 className="ml-2 text-xl font-bold">Jugendkompass</h1>
          </div>
        ) : (
          <BookIcon className="h-6 w-6 text-sidebar-primary" />
        )}
      </div>
      
      {/* Navigationsmenü */}
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
              
              {/* Untermenüpunkte, nur anzeigen wenn erweitert und aktiv */}
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
      
      {/* Benutzerbereich und Abmelden-Knopf */}
      <div className={cn(
        "mt-auto pt-4 border-t border-sidebar-border",
        collapsed ? "w-full flex justify-center" : ""
      )}>
        <Button
          variant="ghost"
          className={cn(
            "w-full justify-start text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
            collapsed ? "h-10 w-10 p-0 flex items-center justify-center" : "px-3 py-2"
          )}
          onClick={logout}
        >
          <LogOutIcon className="h-5 w-5" />
          {!collapsed && <span className="ml-3">Abmelden</span>}
        </Button>
      </div>
    </div>
  );
};
