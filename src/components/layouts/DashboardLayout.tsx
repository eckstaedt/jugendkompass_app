
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import { ArrowLeftIcon, MenuIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';

type DashboardLayoutProps = {
  children: React.ReactNode;
  title: string;
};

export const DashboardLayout = ({ children, title }: DashboardLayoutProps) => {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const { user, loading, isAdmin } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    const checkMobile = () => {
      if (window.innerWidth < 768) {
        setSidebarOpen(false);
      } else {
        setSidebarOpen(true);
      }
    };
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => {
      window.removeEventListener('resize', checkMobile);
    };
  }, []);

  useEffect(() => {
    if (!loading && !user) {
      navigate('/login');
      toast({
        title: "Zugang verweigert",
        description: "Bitte melde dich an, um auf das Dashboard zuzugreifen.",
        variant: "destructive"
      });
    }
    if (!loading && user && !isAdmin) {
      navigate('/login');
      toast({
        title: "Zugang verweigert",
        description: "Du benötigst Administratorrechte für diesen Bereich.",
        variant: "destructive"
      });
    }
  }, [user, loading, isAdmin, navigate, toast, title]);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
      </div>
    );
  }

  // Adjusted header height to h-20 for all dashboard pages for consistency
  return (
    <div className="flex h-screen overflow-hidden">
      <div className={`fixed inset-y-0 left-0 z-50 w-64 transform transition-transform duration-200 ease-in-out bg-sidebar md:relative ${sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0 md:w-16'}`}>
        <Sidebar collapsed={!sidebarOpen} />
      </div>
      <div className="flex flex-1 flex-col overflow-y-auto">
        <header className="sticky top-0 z-10 flex h-20 items-center border-b bg-white dark:bg-background px-4 shadow-sm">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="mr-4 md:hidden"
          >
            <MenuIcon className="h-5 w-5" />
            <span className="sr-only">Menü öffnen</span>
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="mr-4 hidden md:flex"
          >
            {sidebarOpen ? (
              <ArrowLeftIcon className="h-5 w-5" />
            ) : (
              <MenuIcon className="h-5 w-5" />
            )}
            <span className="sr-only">
              Seitenleiste {sidebarOpen ? 'einklappen' : 'ausklappen'}
            </span>
          </Button>
          <h1 className="text-xl font-semibold">{title}</h1>
        </header>
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  );
};

