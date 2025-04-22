
import * as React from "react";
import { Suspense } from "react";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from '@/contexts/AuthContext';
import Index from "./pages/index";
import NotFound from "./pages/NotFound";

// Lazy load pages
const LoginPage = React.lazy(() => import('./pages/login/index'));
const DashboardPage = React.lazy(() => import('./pages/dashboard'));
const PostsPage = React.lazy(() => import('./pages/dashboard/posts'));
const UsersPage = React.lazy(() => import('./pages/dashboard/users'));

// Loading fallback
const PageLoading = () => (
  <div className="flex h-screen items-center justify-center">
    <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
  </div>
);

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <AuthProvider>
        <TooltipProvider>
          <Toaster />
          <Sonner />
          <Suspense fallback={<PageLoading />}>
            <Routes>
              <Route path="/" element={<Index />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/dashboard" element={<DashboardPage />} />
              <Route path="/dashboard/posts" element={<PostsPage />} />
              <Route path="/dashboard/posts/new" element={<div>Neuer Beitrag</div>} />
              <Route path="/dashboard/posts/:id" element={<div>Beitrag anzeigen</div>} />
              <Route path="/dashboard/posts/:id/edit" element={<div>Beitrag bearbeiten</div>} />
              <Route path="/dashboard/posts/categories" element={<div>Kategorien verwalten</div>} />
              <Route path="/dashboard/posts/editions" element={<div>Editionen verwalten</div>} />
              <Route path="/dashboard/polls" element={<div>Umfragen verwalten</div>} />
              <Route path="/dashboard/polls/new" element={<div>Neue Umfrage</div>} />
              <Route path="/dashboard/polls/stats" element={<div>Umfrage-Statistiken</div>} />
              <Route path="/dashboard/videos" element={<div>Videos verwalten</div>} />
              <Route path="/dashboard/videos/new" element={<div>Neues Video</div>} />
              <Route path="/dashboard/daily-verses" element={<div>Tagesverse verwalten</div>} />
              <Route path="/dashboard/daily-verses/new" element={<div>Neuer Tagesvers</div>} />
              <Route path="/dashboard/users" element={<UsersPage />} />
              <Route path="/dashboard/statistics" element={<div>App-Statistiken</div>} />
              <Route path="/dashboard/notifications" element={<div>Benachrichtigungen verwalten</div>} />
              <Route path="/dashboard/notifications/new" element={<div>Neue Benachrichtigung</div>} />
              <Route path="/dashboard/settings" element={<div>Einstellungen</div>} />
              {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </Suspense>
        </TooltipProvider>
      </AuthProvider>
    </BrowserRouter>
  </QueryClientProvider>
);

export default App;
