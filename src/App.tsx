
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
const NewPostPage = React.lazy(() => import('./pages/dashboard/posts/new'));
const CategoriesPage = React.lazy(() => import('./pages/dashboard/posts/categories'));
const EditionsPage = React.lazy(() => import('./pages/dashboard/posts/editions'));
const UsersPage = React.lazy(() => import('./pages/dashboard/users'));
const EditPostPage = React.lazy(() => import('./pages/dashboard/posts/edit'));
const DailyVersesPage = React.lazy(() => import('./pages/dashboard/daily-verses'));
const PollsPage = React.lazy(() => import('./pages/dashboard/polls'));
const NewPollPage = React.lazy(() => import('./pages/dashboard/polls/new'));
const PollDetailPage = React.lazy(() => import('./pages/dashboard/polls/[id]'));

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
              <Route path="/dashboard/posts/new" element={<NewPostPage />} />
              <Route path="/dashboard/posts/categories" element={<CategoriesPage />} />
              <Route path="/dashboard/posts/ausgaben" element={<EditionsPage />} />
              <Route path="/dashboard/polls" element={<PollsPage />} />
              <Route path="/dashboard/polls/new" element={<NewPollPage />} />
              <Route path="/dashboard/polls/:id" element={<PollDetailPage />} />
              <Route path="/dashboard/polls/stats" element={<div>Umfrage-Statistiken</div>} />
              <Route path="/dashboard/videos" element={<div>Videos verwalten</div>} />
              <Route path="/dashboard/videos/new" element={<div>Neues Video</div>} />
              <Route path="/dashboard/daily-verses" element={<DailyVersesPage />} />
              <Route path="/dashboard/daily-verses/new" element={<DailyVersesPage />} />
              <Route path="/dashboard/users" element={<UsersPage />} />
              <Route path="/dashboard/statistics" element={<div>App-Statistiken</div>} />
              <Route path="/dashboard/notifications" element={<div>Benachrichtigungen verwalten</div>} />
              <Route path="/dashboard/notifications/new" element={<div>Neue Benachrichtigung</div>} />
              <Route path="/dashboard/settings" element={<div>Einstellungen</div>} />
              <Route path="/dashboard/posts/edit/:id" element={<EditPostPage />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </Suspense>
        </TooltipProvider>
      </AuthProvider>
    </BrowserRouter>
  </QueryClientProvider>
);

export default App;
